#ifndef gpio_h
#define gpio_h

#include <fcntl.h>
#include <stdio.h>
#include <syslog.h>

int ir_cut_get(void);
int ir_cut_set(int state);

#endif
