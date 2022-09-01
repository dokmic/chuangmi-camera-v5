#ifndef isp328_h
#define isp328_h

#include <fcntl.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <syslog.h>
#include <unistd.h>

int get_flip_fliter(void);
int set_flip_fliter(int state);

int get_mirror_fliter(void);
int set_mirror_fliter(int state);

int get_night_fliter(void);
int set_night_fliter(int state);

#endif
