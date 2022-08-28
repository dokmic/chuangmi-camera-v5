#include "led.h"

#define BLUE_LED_BRIGHTNESS "/sys/class/leds/BLUE/brightness"
#define BLUE_LED_DELAY_ON "/sys/class/leds/BLUE/delay_on"

int get_blue_led(void)
{
    int fd = open(BLUE_LED_BRIGHTNESS, O_RDONLY);
    if (fd == -1) {
        syslog(LOG_ERR, "Failed to open %s", BLUE_LED_BRIGHTNESS);

        return 0;
    }

    char value[6];
    if (read(fd, value, 3) == -1) {
        syslog(LOG_ERR, "Failed to read value from %s", BLUE_LED_BRIGHTNESS);

        return 0;
    }

    close(fd);

    int brightness = atoi(value);

    if (!brightness && access(BLUE_LED_DELAY_ON, F_OK)) {
        return 0;
    }

    return 1;
}

int set_blue_led(int state)
{
    FILE *fd = fopen(BLUE_LED_BRIGHTNESS, "w");
    if (!fd) {
        syslog(LOG_ERR, "Failed to open %s", BLUE_LED_BRIGHTNESS);

        return 0;
    }

    fprintf(fd, "%d", state ? 50 : 0);
    fclose(fd);

    return 1;
}
