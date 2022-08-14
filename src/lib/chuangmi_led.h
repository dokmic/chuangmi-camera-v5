#ifndef chuangmi_led_h
#define chuangmi_led_h

#define BLUE_LED_BRIGHTNESS "/sys/class/leds/BLUE/brightness"
#define BLUE_LED_DELAY_ON   "/sys/class/leds/BLUE/delay_on"

int blue_led_on(void);
int blue_led_off(void);
int blue_led_status(void);

#endif


