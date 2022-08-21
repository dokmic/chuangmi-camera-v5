#ifndef isp328_h
#define isp328_h

#include <fcntl.h>
#include <sys/ioctl.h>
#include <syslog.h>

int flip_mode_get(void);
int flip_mode_set(int state);

int mirror_mode_get(void);
int mirror_mode_set(int state);

int night_mode_get(void);
int night_mode_set(int state);

unsigned int light_info_get(void);

#endif
