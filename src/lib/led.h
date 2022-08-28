#ifndef led_h
#define led_h

#include <fcntl.h>
#include <stdio.h>
#include <syslog.h>

int get_blue_led(void);
int set_blue_led(int state);

#endif
