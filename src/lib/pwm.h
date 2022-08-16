#ifndef pwm_h
#define pwm_h

#include <fcntl.h>
#include <string.h>
#include <sys/ioctl.h>
#include <syslog.h>

int ir_led_get(void);
int ir_led_set(int state);

#endif
