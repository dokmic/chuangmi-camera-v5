
## The third party binaries in prefix/sbin that should be stripped and copied to firmware/bin
THIRD_PARTY_SBINS :=	\
	logrotate

## The third party binaries in prefix/bin that should be stripped and copied to firmware/bin
THIRD_PARTY_BINS :=	\
	busybox	   	\
	ffmpeg	   	\
	ffprobe

## Third party library files that should be stripped and copied to firmware/lib
THIRD_PARTY_LIBS :=			\
	libavcodec.so.58.18.100		\
	libavdevice.so.58.3.100		\
	libavfilter.so.7.16.100		\
	libavformat.so.58.12.100	\
	libavutil.so.56.14.100		\
	libpopt.so.0.0.0		\
	libpostproc.so.55.1.100		\
	libswresample.so.3.1.100	\
	libswscale.so.5.1.100		\
	libx264.so.161			\
	libz.a				\
	libz.so.$(ZLIBVERSION)


## The symlinks to library files that should be copied to firmware/lib but not stripped
THIRD_PARTY_LIB_EXTRAS :=		\
	libavcodec.so			\
	libavcodec.so.58		\
	libavdevice.so			\
	libavdevice.so.58		\
	libavfilter.so			\
	libavfilter.so.7		\
	libavformat.so			\
	libavformat.so.58		\
	libavutil.so			\
	libavutil.so.56			\
	libpopt.so			\
	libpopt.so.0			\
	libpostproc.so			\
	libpostproc.so.55		\
	libswresample.so		\
	libswresample.so.3		\
	libswscale.so			\
	libswscale.so.5			\
	libx264.so			\
	libz.so				\
	libz.so.1

