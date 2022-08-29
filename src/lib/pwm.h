#ifndef pwm_h
#define pwm_h

#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <syslog.h>
#include <unistd.h>

int get_ir_led(void);
int set_ir_led(int state);

#endif
