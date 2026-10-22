#!/usr/bin/env python3
"""Check the actual lab C hotpaths against a scalar reference (no GPU needed)."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile

mesa = Path(sys.argv[1] if len(sys.argv) > 1 else '/home/gean/Documents/nouveau-lab/src/mesa')
src = mesa / 'src/gallium/drivers/nouveau'


def function(text, name):
    start = text.index('\n' + name + '(') + 1
    body = text.index('{', start)
    depth = 1
    end = body + 1
    while depth:
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    return text[start:end]


backend = (src / 'nouveau_nvenc_backend.c').read_text()
h264 = (src / 'nouveau_vk_video_h264.c').read_text()
code = r'''
#define _POSIX_C_SOURCE 200809L
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <time.h>
enum { SLOT_INPUT_Y, SLOT_INPUT_UV };
struct buffer { void *map; };
struct slot { struct buffer buffers[2]; };
struct nvenc_backend { unsigned coded_height, height, pitch, width; };
#define NOUVEAU_VK_H264_MAX_BITSTREAM (16u * 1024u * 1024u)
struct nouveau_vk_h264_bitstream { uint8_t *data; size_t size, capacity; };
'''
code += 'static uint64_t\n' + function(backend, 'gob_offset') + '\n'
code += 'static void\n' + function(backend, 'upload') + '\n'
code += 'bool\n' + function(h264, 'nouveau_vk_h264_append') + '\n'
code += r'''
static void reference(const struct nvenc_backend *s, struct slot *slot,
                      const uint8_t *y, unsigned yp, const uint8_t *uv, unsigned uvp) {
    const uint8_t *planes[]={y,uv}; const unsigned pitches[]={yp,uvp};
    for(unsigned p=0;p<2;p++) {
        uint8_t *map=slot->buffers[p].map;
        for(unsigned row=0;row<(s->coded_height>>p);row++) {
            unsigned sy=row<(s->height>>p)?row:(s->height>>p)-1;
            for(unsigned x=0;x<s->pitch;x++) {
                unsigned sx=x<s->width?x:s->width-(p?2:1)+(p?x%2:0);
                map[gob_offset(x,row,s->pitch,2)]=planes[p][(size_t)sy*pitches[p]+sx];
            }
        }
    }
}
static double now(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC,&t); return t.tv_sec+t.tv_nsec*1e-9; }
int main(void) {
    const unsigned widths[]={2,4,14,16,18,30,32,34,62,64,66,126,128,130,1918,1920,1922,3840};
    const unsigned heights[]={2,14,16,18,30,32,34,1080};
    unsigned cases=0;
    for(unsigned wi=0;wi<sizeof(widths)/sizeof(widths[0]);wi++)
    for(unsigned hi=0;hi<sizeof(heights)/sizeof(heights[0]);hi++) {
        struct nvenc_backend s={.width=widths[wi],.height=heights[hi],.pitch=(widths[wi]+127)&~127u,.coded_height=(heights[hi]+15)&~15u};
        size_t bytes=(size_t)s.pitch*s.coded_height;
        unsigned input_pitch=s.width+22;
        uint8_t *input=malloc((size_t)input_pitch*s.height);
        assert(input);
        for(size_t i=0;i<(size_t)input_pitch*s.height;i++) input[i]=(i*37+i/257)&255;
        struct slot a,b;
        for(unsigned p=0;p<2;p++) {
            a.buffers[p].map=malloc(bytes); b.buffers[p].map=malloc(bytes);
            assert(a.buffers[p].map && b.buffers[p].map);
            memset(a.buffers[p].map,0xa5,bytes); memset(b.buffers[p].map,0xa5,bytes);
        }
        reference(&s,&a,input,input_pitch,input,input_pitch);
        upload(&s,&b,input,input_pitch,input,input_pitch);
        for(unsigned p=0;p<2;p++) assert(!memcmp(a.buffers[p].map,b.buffers[p].map,bytes));
        if(s.width==1920 && s.height==1080) {
            double t=now(); for(unsigned i=0;i<30;i++) reference(&s,&a,input,input_pitch,input,input_pitch);
            double old=now()-t; t=now(); for(unsigned i=0;i<30;i++) upload(&s,&b,input,input_pitch,input,input_pitch);
            printf("1080p CPU upload: scalar %.3f ms, block %.3f ms/frame\n",old*1000/30,(now()-t)*1000/30);
        }
        for(unsigned p=0;p<2;p++) { free(a.buffers[p].map); free(b.buffers[p].map); }
        free(input); cases++;
    }
    struct nouveau_vk_h264_bitstream stream={0};
    uint8_t data[1031]; memset(data,0x79,sizeof(data));
    const void *buffers[]={data}; const unsigned sizes[]={sizeof(data)};
    unsigned allocations=0; size_t capacity=0;
    for(unsigned i=0;i<1000;i++) {
        assert(nouveau_vk_h264_append(&stream,1,buffers,sizes));
        if(capacity!=stream.capacity) { allocations++; capacity=stream.capacity; }
    }
    assert(stream.size==1000*sizeof(data) && stream.capacity>=stream.size);
    assert(allocations<=10);
    for(size_t i=0;i<stream.size;i++) assert(stream.data[i]==0x79);
    const unsigned too_large[]={NOUVEAU_VK_H264_MAX_BITSTREAM};
    assert(!nouveau_vk_h264_append(&stream,1,buffers,too_large));
    const void *null_buffer[]={NULL};
    assert(!nouveau_vk_h264_append(&stream,1,null_buffer,sizes));
    assert(nouveau_vk_h264_append(&stream,0,NULL,NULL));
    free(stream.data);
    printf("PASS: %u NV12 edge/pitch cases; H.264 contents, bounds, %u growth allocations\n",cases,allocations);
    return 0;
}
'''
with tempfile.TemporaryDirectory(prefix='nvgd-video-', dir=os.environ.get('TMPDIR', '/tmp/opencode')) as tmp:
    c = Path(tmp) / 'check.c'
    binary = Path(tmp) / 'check'
    c.write_text(code)
    flags = ['-fsanitize=address,undefined', '-fno-omit-frame-pointer'] if os.environ.get('NVGD_TEST_SANITIZE') else []
    subprocess.run(['gcc', '-O2', '-Wall', '-Wextra', '-Werror', *flags, str(c), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
