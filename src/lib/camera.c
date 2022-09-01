#include "camera.h"

#include "gpio.c"
#include "isp328.c"
#include "led.c"
#include "pwm.c"

int get_ceiling_mode(void)
{
    return get_flip_filter() && get_mirror_filter();
}

int set_ceiling_mode(int state)
{
    return set_flip_filter(state) && set_mirror_filter(state);
}

int get_night_mode(void)
{
    return get_ir_cut() && get_night_filter();
}

int set_night_mode(int state)
{
    return set_ir_cut(state) && set_ir_led(state) && set_night_filter(state);
}
