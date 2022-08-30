#include "led.h"

#define LED_BRIGHTNESS "/sys/class/leds/%s/brightness"
#define LED_DELAY "/sys/class/leds/%s/delay_on"

int get_led(char *color) {
    char path[strlen(LED_BRIGHTNESS) + strlen(color) + 1];
    sprintf(path, LED_BRIGHTNESS, color);

    int fd = open(path, O_RDONLY);
    if (fd == -1) {
        syslog(LOG_ERR, "Failed to open %s", path);

        return 0;
    }

    char value[6];
    if (read(fd, value, 3) == -1) {
        syslog(LOG_ERR, "Failed to read value from %s", path);

        return 0;
    }

    close(fd);

    int brightness = atoi(value);
    char delay[strlen(LED_DELAY) + strlen(color) + 1];
    sprintf(delay, LED_DELAY, color);

    if (!brightness && access(delay, F_OK)) {
        return 0;
    }

    return 1;
}

int set_led(char *color, int state) {
    char path[strlen(LED_BRIGHTNESS) + strlen(color) + 1];
    sprintf(path, LED_BRIGHTNESS, color);

    FILE *fd = fopen(path, "w");
    if (!fd) {
        syslog(LOG_ERR, "Failed to open %s", path);

        return 0;
    }

    fprintf(fd, "%d", state ? 50 : 0);
    fclose(fd);

    return 1;
}

int get_blue_led(void)
{
    return get_led("BLUE");
}

int set_blue_led(int state)
{
    return set_led("BLUE", state);
}

int get_yellow_led(void)
{
    return get_led("RED");
}

int set_yellow_led(int state)
{
    return set_led("RED", state);
}
