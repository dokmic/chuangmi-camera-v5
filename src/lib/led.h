#ifndef led_h
#define led_h

#include <fcntl.h>
#include <stdio.h>
#include <syslog.h>

int blue_led_get(void);
int blue_led_set(int state);

#endif
