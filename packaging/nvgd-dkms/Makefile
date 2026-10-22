KDIR ?= /lib/modules/$(shell uname -r)/build

modules:
	$(MAKE) -C $(KDIR) M=$(CURDIR) LLVM=1 NOUVEAU_LAB_PIN_GSP=y \
		KCFLAGS='-include $(CURDIR)/lab-uapi/nouveau_drm.h -I$(KDIR)/include/uapi/drm' modules

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR) LLVM=1 clean

.PHONY: modules clean
