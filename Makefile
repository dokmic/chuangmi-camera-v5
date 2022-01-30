
TOOLCHAINDIR := /usr/src/arm-linux-3.3/toolchain_gnueabi-4.4.0_ARMv5TE/usr/bin
PATH         := $(TOOLCHAINDIR):$(PATH)
TARGET       := arm-unknown-linux-uclibcgnueabi
PROCS        := $(shell nproc --all )

DOWNLOADCMD := curl -qs --http1.1 -L --retry 10 --output

TOPDIR         := $(CURDIR)
BUILDDIR       := $(TOPDIR)/build
TOOLSDIR       := $(TOPDIR)/tools

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

GMLIBDIR       := $(TOOLSDIR)/gm_lib
RTSPDDIR       := $(TOOLSDIR)/rtsp_server
UTILSDIR       := $(TOOLSDIR)/utils

SOURCES        := $(TOPDIR)/sources.json

#################################################################
## Functions                                                   ##
#################################################################

include tools/make/functions.mk


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
	$(call box,"Compiling miicam library $(@F)")
	CPPFLAGS="-I$(TOOLSDIR)/lib -L$(BUILDDIR)/lib" \
	LDFLAGS=" -I$(TOOLSDIR)/lib -L$(BUILDDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags" \
	$(TARGET)-gcc -shared -o $(BUILDDIR)/lib/libchuangmi_utils.so -fPIC $(TOOLSDIR)/lib/chuangmi_utils.c
	@touch $@

$(BUILDDIR)/chuangmi_ircut: $(BUILDDIR)/lib $(BUILDDIR)/chuangmi_utils
	$(call box,"Compiling miicam library $(@F)")
	CPPFLAGS="-I$(TOOLSDIR)/lib -L$(BUILDDIR)/lib" \
	LDFLAGS=" -I$(TOOLSDIR)/lib -L$(BUILDDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags" \
	$(TARGET)-gcc -shared -o $(BUILDDIR)/lib/libchuangmi_ircut.so -fPIC $(TOOLSDIR)/lib/chuangmi_ircut.c
	@touch $@

$(BUILDDIR)/chuangmi_isp328: $(BUILDDIR)/lib $(BUILDDIR)/chuangmi_utils
	$(call box,"Compiling miicam library $(@F)")
	CPPFLAGS="-I$(TOOLSDIR)/lib -L$(BUILDDIR)/lib" \
	LDFLAGS=" -I$(TOOLSDIR)/lib -L$(BUILDDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags" \
	$(TARGET)-gcc -shared -o $(BUILDDIR)/lib/libchuangmi_isp328.so -fPIC $(TOOLSDIR)/lib/chuangmi_isp328.c
	@touch $@

$(BUILDDIR)/chuangmi_pwm: $(BUILDDIR)/lib $(BUILDDIR)/chuangmi_utils
	$(call box,"Compiling miicam library $(@F)")
	CPPFLAGS="-I$(TOOLSDIR)/lib -L$(BUILDDIR)/lib" \
	LDFLAGS=" -I$(TOOLSDIR)/lib -L$(BUILDDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags" \
	$(TARGET)-gcc -shared -o $(BUILDDIR)/lib/libchuangmi_pwm.so -fPIC $(TOOLSDIR)/lib/chuangmi_pwm.c
	@touch $@

$(BUILDDIR)/chuangmi_led: $(BUILDDIR)/lib $(BUILDDIR)/chuangmi_utils
	$(call box,"Compiling miicam library $(@F)")
	CPPFLAGS="-I$(TOOLSDIR)/lib -L$(BUILDDIR)/lib" \
	LDFLAGS=" -I$(TOOLSDIR)/lib -L$(BUILDDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags" \
	$(TARGET)-gcc -shared -o $(BUILDDIR)/lib/libchuangmi_led.so -fPIC $(TOOLSDIR)/lib/chuangmi_led.c
	@touch $@


#################################################################
## UTILS                                                       ##
#################################################################

$(UTILS): $(BUILDDIR)/bin $(LIBS) $(BUILDDIR)/popt
	$(call box,"Compiling miicam utility $(@F)")
	CPPFLAGS="-I$(TOOLSDIR)/lib -L$(BUILDDIR)/lib" \
	LDFLAGS=" -I$(TOOLSDIR)/lib -L$(BUILDDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags" \
	$(TARGET)-gcc \
		-Wall \
		-o $(BUILDDIR)/bin/$(@F) $(UTILSDIR)/$(@F).c \
		-I $(TOOLSDIR)/lib \
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
	$(call box,"Compiling miicam libraries")
	cd $(GMLIBDIR)			\
	&& $(TARGET)-gcc		\
		-Wall			\
		-I $(GMLIBDIR)/inc	\
		-I $(TOOLSDIR)/lib	\
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
	$(TOPDIR)/sdcard/firmware/scripts/configupdate $(BUILDDIR)/config.cfg

manufacture.bin:
	tar -cf $(BUILDDIR)/manufacture.bin manufacture/test_drv

#################################################################
## Third party tools                                           ##
#################################################################

include tools/make/zlib.mk
include tools/make/libpopt.mk
include tools/make/busybox.mk

#################################################################
##                                                             ##
#################################################################

.PHONY: default install dist clean

install: default
	rm -rf $(BUILDDIR)/dist \
	&& mkdir -p $(BUILDDIR)/dist \
	&& cp -r --preserve=links $(TOPDIR)/sdcard  $(BUILDDIR)/dist \
	&& cp $(BUILDDIR)/manufacture.bin $(BUILDDIR)/config.cfg $(BUILDDIR)/dist/sdcard \
	&& mkdir -p $(BUILDDIR)/dist/sdcard/firmware/bin $(BUILDDIR)/dist/sdcard/firmware/lib \
	&& find $(BUILDDIR)/lib -maxdepth 1 \( -type f -or -type l \) \( -name '*.so*' -or -name '*.a*' \) -exec cp --no-dereference {} $(BUILDDIR)/dist/sdcard/firmware/lib/. \; \
	&& find $(BUILDDIR)/bin -maxdepth 1 -type f -exec cp {} $(BUILDDIR)/dist/sdcard/firmware/bin \;

dist: install
	tar czf $(BUILDDIR)/MiiCam.tar.gz -C $(BUILDDIR)/dist sdcard \
	&& md5sum $(BUILDDIR)/MiiCam.tar.gz > $(BUILDDIR)/MiiCam.tar.gz.md5

clean:
	rm -rf $(BUILDDIR)
