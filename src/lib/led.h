#ifndef led_h
#define led_h

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <unistd.h>

int get_blue_led(void);
int set_blue_led(int state);

int get_yellow_led(void);
int set_yellow_led(int state);

#endif
