/*
 * Originally taken from mijia_ctrl
 * by cck56
 */

#include <assert.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "chuangmi_led.h"

int read_int(const char *filename)
{
    int fd;
    fd = open(filename, O_RDONLY);
    if (fd == -1) {
        fprintf(stderr, "Failed to open %s for reading!\n", filename);
        return -1;
    }

    char value_str[6];
    if (read(fd, value_str, 3) == -1) {
        fprintf(stderr, "Failed to read value from %s!\n", filename);
        return -1;
    }

    close(fd);
    return atoi(value_str);
}

int write_file(const char *file_path, char *content)
{
    FILE *fd;

    fd = fopen(file_path, "w");
    if (!fd) {
        fprintf(stderr, "Error: Failed to open: %s\n", file_path);
        return -1;
    }

    fprintf(fd, content);
    fclose(fd);

    return 0;
}

int blue_led_get_brightness(void)
{
    int brightness = read_int(BLUE_LED_BRIGHTNESS);
    if (brightness < 0) {
        return -1;
    }
    return brightness;
}

int blue_led_set_brightness(int value)
{
    char numstring[5];
    snprintf(numstring, sizeof numstring, "%d", value);

    if (write_file(BLUE_LED_BRIGHTNESS, numstring) < 0) {
        return -1;
    }

    return 0;
}

int blue_led_on(void)
{
    int success = blue_led_set_brightness(50);

    if (success < 0) {
        fprintf(stderr, "Failed to turn the blue led on\n");
        return -1;
    }

    fprintf(stderr, "The blue led was turned on\n");
    return 0;
}

int blue_led_off(void)
{
    if (blue_led_set_brightness(0) < 0) {
        fprintf(stderr, "Failed to turn the blue led off\n");
        return -1;
    }

    fprintf(stderr, "The blue led was set off\n");
    return 0;
}

int blue_led_status(void)
{
    int brightness = blue_led_get_brightness();

    if (access(BLUE_LED_DELAY_ON, F_OK) == 0 || brightness > 0) {
        fprintf(stdout, "on\n");
    }
    else if (brightness == 0) {
        fprintf(stdout, "off\n");
    }
    else {
        fprintf(stdout, "unknown (brightness=%d)\n", brightness);
        return -1;
    }

    return 0;
}
