#ifndef gpio_h
#define gpio_h

#include <fcntl.h>
#include <stdio.h>
#include <syslog.h>

int get_ir_cut(void);
int set_ir_cut(int state);

#endif
