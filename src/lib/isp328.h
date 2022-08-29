#ifndef isp328_h
#define isp328_h

#include <fcntl.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <syslog.h>
#include <unistd.h>

int get_flip_mode(void);
int set_flip_mode(int state);

int get_mirror_mode(void);
int set_mirror_mode(int state);

int get_night_mode(void);
int set_night_mode(int state);

unsigned int get_light_info(void);

#endif
