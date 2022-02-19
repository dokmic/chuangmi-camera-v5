
TOOLCHAINDIR := /usr/src/arm-linux-3.3/toolchain_gnueabi-4.4.0_ARMv5TE/usr/bin
PATH         := $(TOOLCHAINDIR):$(PATH)
TARGET       := arm-unknown-linux-uclibcgnueabi
PROCS        := $(shell nproc --all )

DOWNLOADCMD := curl -qs --http1.1 -L --retry 10 --output

BUILDDIR       := $(CURDIR)/build
SRCDIR         := $(CURDIR)/src
SOURCES        := $(CURDIR)/sources.json

BUILDENV :=			\
	AR=$(TARGET)-ar		\
	AS=$(TARGET)-as		\
	CC=$(TARGET)-gcc	\
	CXX=$(TARGET)-g++	\
	LD=${TARGET}-ld		\
	LDSHARED="$(TARGET)-gcc -shared"		\
	NM=$(TARGET)-nm		\
	RANLIB=$(TARGET)-ranlib	\
	STRIP=$(TARGET)-strip	\
	CFLAGS="-fPIC"		\
	CPPFLAGS="-I$(BUILDDIR)/include -L$(BUILDDIR)/lib" \
	LDFLAGS=" -I$(BUILDDIR)/include -L$(BUILDDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags"

GMLIBDIR       := $(SRCDIR)/gm_lib
RTSPDDIR       := $(SRCDIR)/rtsp_server
UTILSDIR       := $(SRCDIR)/utils

#################################################################
## Results                                                     ##
#################################################################

LIBS :=					\
	$(BUILDDIR)/chuangmi_ircut	\
	$(BUILDDIR)/chuangmi_isp328	\
	$(BUILDDIR)/chuangmi_pwm	\
	$(BUILDDIR)/chuangmi_led	\
	$(BUILDDIR)/chuangmi_utils

UTILS :=				\
	$(BUILDDIR)/chuangmi_ctrl	\
	$(BUILDDIR)/take_snapshot	\
	$(BUILDDIR)/take_video		\
	$(BUILDDIR)/ir_cut		\
	$(BUILDDIR)/ir_led		\
	$(BUILDDIR)/blue_led		\
	$(BUILDDIR)/yellow_led		\
	$(BUILDDIR)/mirrormode		\
	$(BUILDDIR)/nightmode		\
	$(BUILDDIR)/flipmode		\
	$(BUILDDIR)/camera_adjust	\
	$(BUILDDIR)/auto_night_mode

GMUTILS :=				\
	$(BUILDDIR)/audio_playback	\
	$(BUILDDIR)/encode_with_osd	\
	$(BUILDDIR)/osd

THIRD_PARTY_SOFTWARE :=			\
	$(BUILDDIR)/zlib		\
	$(BUILDDIR)/popt		\
	$(BUILDDIR)/busybox

libs: $(LIBS)

third-party: $(THIRD_PARTY_SOFTWARE)

utils: $(UTILS)

libs: $(LIBS)

gmutils: $(GMUTILS)

default:					\
	libs				\
	utils				\
	gmutils				\
	config.cfg		\
	manufacture.bin		\
	$(BUILDDIR)/rtspd		\
	third-party
	find $(BUILDDIR)/lib -maxdepth 1 -type f -name '*.so*' -or -name '*.a*' -exec $(TARGET)-strip {} \; \
	&& find $(BUILDDIR)/bin -maxdepth 1 -type f -exec $(TARGET)-strip {} \;

#################################################################
## DIRS                                                        ##
#################################################################

$(BUILDDIR)/bin:
	@mkdir -p $(BUILDDIR)/bin

$(BUILDDIR)/sbin:
	@mkdir -p $(BUILDDIR)/sbin

$(BUILDDIR)/lib:
	@mkdir -p $(BUILDDIR)/lib

#################################################################
## RTSPD                                                       ##
#################################################################

$(BUILDDIR)/rtspd: $(BUILDDIR)/bin
	cd $(RTSPDDIR)			\
	&& $(TARGET)-gcc		\
		-DLOG_USE_COLOR		\
		-Wall			\
		-I$(GMLIBDIR)/inc	\
		$(RTSPDDIR)/$(@F).c	\
		$(RTSPDDIR)/log/log.c	\
		$(RTSPDDIR)/librtsp.a	\
		-L$(GMLIBDIR)/lib	\
		-lpthread -lm -lrt -lgm -o $(BUILDDIR)/bin/rtspd && \
		$(TARGET)-strip $(BUILDDIR)/bin/rtspd
	@touch $@


#################################################################
## LIBS                                                        ##
#################################################################

$(BUILDDIR)/chuangmi_utils: $(BUILDDIR)/lib
	CPPFLAGS="-I$(SRCDIR)/lib -L$(BUILDDIR)/lib" \
	LDFLAGS=" -I$(SRCDIR)/lib -L$(BUILDDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags" \
	$(TARGET)-gcc -shared -o $(BUILDDIR)/lib/libchuangmi_utils.so -fPIC $(SRCDIR)/lib/chuangmi_utils.c
	@touch $@

$(BUILDDIR)/chuangmi_ircut: $(BUILDDIR)/lib $(BUILDDIR)/chuangmi_utils
	CPPFLAGS="-I$(SRCDIR)/lib -L$(BUILDDIR)/lib" \
	LDFLAGS=" -I$(SRCDIR)/lib -L$(BUILDDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags" \
	$(TARGET)-gcc -shared -o $(BUILDDIR)/lib/libchuangmi_ircut.so -fPIC $(SRCDIR)/lib/chuangmi_ircut.c
	@touch $@

$(BUILDDIR)/chuangmi_isp328: $(BUILDDIR)/lib $(BUILDDIR)/chuangmi_utils
	CPPFLAGS="-I$(SRCDIR)/lib -L$(BUILDDIR)/lib" \
	LDFLAGS=" -I$(SRCDIR)/lib -L$(BUILDDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags" \
	$(TARGET)-gcc -shared -o $(BUILDDIR)/lib/libchuangmi_isp328.so -fPIC $(SRCDIR)/lib/chuangmi_isp328.c
	@touch $@

$(BUILDDIR)/chuangmi_pwm: $(BUILDDIR)/lib $(BUILDDIR)/chuangmi_utils
	CPPFLAGS="-I$(SRCDIR)/lib -L$(BUILDDIR)/lib" \
	LDFLAGS=" -I$(SRCDIR)/lib -L$(BUILDDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags" \
	$(TARGET)-gcc -shared -o $(BUILDDIR)/lib/libchuangmi_pwm.so -fPIC $(SRCDIR)/lib/chuangmi_pwm.c
	@touch $@

$(BUILDDIR)/chuangmi_led: $(BUILDDIR)/lib $(BUILDDIR)/chuangmi_utils
	CPPFLAGS="-I$(SRCDIR)/lib -L$(BUILDDIR)/lib" \
	LDFLAGS=" -I$(SRCDIR)/lib -L$(BUILDDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags" \
	$(TARGET)-gcc -shared -o $(BUILDDIR)/lib/libchuangmi_led.so -fPIC $(SRCDIR)/lib/chuangmi_led.c
	@touch $@


#################################################################
## UTILS                                                       ##
#################################################################

$(UTILS): $(BUILDDIR)/bin $(LIBS) $(BUILDDIR)/popt
	CPPFLAGS="-I$(SRCDIR)/lib -L$(BUILDDIR)/lib" \
	LDFLAGS=" -I$(SRCDIR)/lib -L$(BUILDDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags" \
	$(TARGET)-gcc \
		-Wall \
		-o $(BUILDDIR)/bin/$(@F) $(UTILSDIR)/$(@F).c \
		-I $(SRCDIR)/lib \
		-I $(BUILDDIR)/include -L$(BUILDDIR)/lib \
		-l popt            \
		-l chuangmi_ircut  \
		-l chuangmi_utils  \
		-l chuangmi_isp328 \
		-l chuangmi_led    \
		-l chuangmi_pwm
	@touch $(BUILDDIR)/$(@F)


#################################################################
## GM Utils                                                    ##
#################################################################

$(GMUTILS): $(BUILDDIR)/popt
	cd $(GMLIBDIR)			\
	&& $(TARGET)-gcc		\
		-Wall			\
		-I $(GMLIBDIR)/inc	\
		-I $(SRCDIR)/lib	\
		-I $(BUILDDIR)/include	\
		-L $(GMLIBDIR)/lib	\
		-L $(BUILDDIR)/lib	\
		-o $(BUILDDIR)/bin/$(@F)\
		$(GMLIBDIR)/$(@F).c	\
		-l gm 			\
		-l m			\
		-l popt			\
		-l rt			\
		-l pthread		\
	&& $(TARGET)-strip $(BUILDDIR)/bin/$(@F)
	@touch $@


#################################################################
## Firmware configuration files                                ##
#################################################################

config.cfg:
	$(SRCDIR)/sdcard/firmware/scripts/configupdate $(BUILDDIR)/config.cfg

manufacture.bin:
	tar -cf $(BUILDDIR)/manufacture.bin -C $(SRCDIR) manufacture/test_drv

#################################################################
## Third party tools                                           ##
#################################################################

BUSYBOX_URL := https://busybox.net/downloads/busybox-1.31.1.tar.bz2
BUSYBOX_ARCHIVE := $(BUILDDIR)/$(notdir $(BUSYBOX_URL))
BUSYBOX_DIR := $(basename $(basename $(BUSYBOX_ARCHIVE)))

$(BUILDDIR)/busybox:
	@test -f $(BUSYBOX_ARCHIVE) \
		|| $(DOWNLOADCMD) $(BUSYBOX_ARCHIVE) $(BUSYBOX_URL) \
		|| rm -f $(BUSYBOX_ARCHIVE)
	@mkdir -p $(BUILDDIR)/bin $(BUILDDIR)/sbin && rm -rf $(BUSYBOX_DIR)
	@tar -xjf $(BUSYBOX_ARCHIVE) -C $(BUILDDIR)
	@cd $(BUSYBOX_DIR) && \
	cp $(SRCDIR)/patches/busybox.config $(BUSYBOX_DIR)/.config 	\
	&& $(BUILDENV)				    									\
		make ARCH=arm CROSS_COMPILE=$(TARGET)- -j$(PROCS)         		\
		&& make ARCH=arm CROSS_COMPILE=$(TARGET)- -j$(PROCS) install 	\
		&& mv $(BUSYBOX_DIR)/_install/bin/busybox $(BUILDDIR)/bin
	@touch $@
	@rm -rf $(BUSYBOX_DIR)

LIBPOPT_URL := http://ftp.rpm.org/mirror/popt/popt-1.16.tar.gz
LIBPOPT_ARCHIVE := $(BUILDDIR)/$(notdir $(LIBPOPT_URL))
LIBPOPT_DIR := $(basename $(basename $(LIBPOPT_ARCHIVE)))

$(BUILDDIR)/popt: $(BUILDDIR)/zlib
	@test -f $(LIBPOPT_ARCHIVE) \
		|| $(DOWNLOADCMD) $(LIBPOPT_ARCHIVE) $(LIBPOPT_URL) \
		|| rm -f $(LIBPOPT_ARCHIVE)
	@mkdir -p $(BUILDDIR) && rm -rf $(LIBPOPT_DIR)
	@tar -xzf $(LIBPOPT_ARCHIVE) -C $(BUILDDIR)
	@cd $(LIBPOPT_DIR)		\
	&& $(BUILDENV)					\
		./configure					\
			--host=$(TARGET)		\
			--prefix=$(BUILDDIR)	\
			--enable-shared			\
			--disable-static		\
		&& make -j$(PROCS)			\
		&& make -j$(PROCS) install
	@rm -rf $(LIBPOPT_DIR)
	@touch $@

ZLIB_URL := https://www.zlib.net/zlib-1.2.12.tar.gz
ZLIB_ARCHIVE := $(BUILDDIR)/$(notdir $(ZLIB_URL))
ZLIB_DIR := $(basename $(basename $(ZLIB_ARCHIVE)))

$(BUILDDIR)/zlib:
	@echo $(ZLIB_DIR)
	@test -f $(ZLIB_ARCHIVE) \
		|| $(DOWNLOADCMD) $(ZLIB_ARCHIVE) $(ZLIB_URL) \
		|| rm -f $(ZLIB_ARCHIVE)
	@mkdir -p $(BUILDDIR) && rm -rf $(ZLIB_DIR)
	@tar -xzf $(ZLIB_ARCHIVE) -C $(BUILDDIR)
	@cd $(ZLIB_DIR)			\
	&& $(BUILDENV)					\
		./configure					\
			--prefix=$(BUILDDIR)	\
			--enable-shared			\
		&& make -j$(PROCS)			\
		&& make -j$(PROCS) install
	@rm -rf $(ZLIB_DIR)
	@touch $@

#################################################################
##                                                             ##
#################################################################

.PHONY: default install dist clean

install: default
	rm -rf $(BUILDDIR)/dist \
	&& mkdir -p $(BUILDDIR)/dist \
	&& cp -r --preserve=links $(SRCDIR)/sdcard  $(BUILDDIR)/dist \
	&& cp $(BUILDDIR)/manufacture.bin $(BUILDDIR)/config.cfg $(BUILDDIR)/dist/sdcard \
	&& mkdir -p $(BUILDDIR)/dist/sdcard/firmware/bin $(BUILDDIR)/dist/sdcard/firmware/lib \
	&& find $(BUILDDIR)/lib -maxdepth 1 \( -type f -or -type l \) \( -name '*.so*' -or -name '*.a*' \) -exec cp --no-dereference {} $(BUILDDIR)/dist/sdcard/firmware/lib/. \; \
	&& find $(BUILDDIR)/bin -maxdepth 1 -type f -exec cp {} $(BUILDDIR)/dist/sdcard/firmware/bin \; \
	&& sync

dist: install
	tar czf $(BUILDDIR)/MiiCam.tar.gz -C $(BUILDDIR)/dist sdcard \
	&& md5sum $(BUILDDIR)/MiiCam.tar.gz > $(BUILDDIR)/MiiCam.tar.gz.md5

clean:
	rm -rf $(BUILDDIR)
