#ifndef camera_h
#define camera_h

#include "gpio.h"
#include "isp328.h"
#include "led.h"
#include "pwm.h"

int get_ceiling_mode(void);
int set_ceiling_mode(int state);

int get_night_mode(void);
int set_night_mode(int state);

#endif
