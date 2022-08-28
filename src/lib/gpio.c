#include "gpio.h"

#define IN  0
#define OUT 1

#define LOW  0
#define HIGH 1

#define GPIO_BUFFER_MAX 3
#define GPIO_DIRECTION_MAX 35
#define GPIO_VALUE_MAX 30

#define GPIO_EXPORT "/sys/class/gpio/export"
#define GPIO_UNEXPORT "/sys/class/gpio/unexport"
#define GPIO_DIRECTION "/sys/class/gpio/gpio%d/direction"
#define GPIO_VALUE "/sys/class/gpio/gpio%d/value"

#define GPIO_PIN_IRCUT_ON 15
#define GPIO_PIN_IRCUT_OFF 14

int export_gpio(int pin)
{
    int fd = open(GPIO_EXPORT, O_WRONLY);
    if (fd == -1) {
        syslog(LOG_ERR, "Failed to open %s for writing", GPIO_EXPORT);

        return 0;
    }

    char buffer[GPIO_BUFFER_MAX];
    ssize_t bytes_written = snprintf(buffer, GPIO_BUFFER_MAX, "%d", pin);
    write(fd, buffer, bytes_written);
    close(fd);

    return 1;
}

int unexport_gpio(int pin)
{
    int fd = open(GPIO_UNEXPORT, O_WRONLY);
    if (fd == -1) {
        syslog(LOG_ERR, "Failed to open %s for writing", GPIO_UNEXPORT);

        return 0;
    }

    char buffer[GPIO_BUFFER_MAX];
    ssize_t bytes_written = snprintf(buffer, GPIO_BUFFER_MAX, "%d", pin);
    write(fd, buffer, bytes_written);
    close(fd);

    return 1;
}

int set_gpio_direction(int pin, int direction)
{
    static const char s_directions_str[]  = "in\0out";

    char path[GPIO_DIRECTION_MAX];
    snprintf(path, GPIO_DIRECTION_MAX, GPIO_DIRECTION, pin);

    int fd = open(path, O_WRONLY);
    if (fd == -1) {
        syslog(LOG_ERR, "Failed to open %s for writing", path);

        return 0;
    }

    if (write(fd, &s_directions_str[IN == direction ? 0 : 3], IN == direction ? 2 : 3) == -1) {
        syslog(LOG_ERR, "Failed to set direction", path);

        return 0;
    }

    close(fd);

    return 1;
}

int is_gpio_active(int pin)
{
    char path[GPIO_VALUE_MAX];
    snprintf(path, GPIO_VALUE_MAX, GPIO_VALUE, pin);

    return !access(path, F_OK);
}

int read_gpio(int pin)
{
    char path[GPIO_VALUE_MAX];
    snprintf(path, GPIO_VALUE_MAX, GPIO_VALUE, pin);

    int fd = open(path, O_RDONLY);
    if (fd == -1) {
        syslog(LOG_ERR, "Failed to open %s for reading", path);

        return -1;
    }

    char value[3];
    if (read(fd, value, 3) == -1) {
        syslog(LOG_ERR, "Failed to read value", path);

        return -1;
    }

    close(fd);

    return atoi(value);
}

int write_gpio(int pin, int value)
{
    char path[GPIO_VALUE_MAX];
    snprintf(path, GPIO_VALUE_MAX, GPIO_VALUE, pin);

    int fd = open(path, O_WRONLY);
    if (fd == -1) {
        syslog(LOG_ERR, "Failed to open %s for writing", path);

        return 0;
    }

    if (write(fd, value ? "1" : "0", 1) != 1) {
        syslog(LOG_ERR, "Failed to write value", path);

        return 0;
    }

    close(fd);

    return 1;
}

int initialize_ir_cut(void)
{
    if (!(is_gpio_active(GPIO_PIN_IRCUT_ON) || export_gpio(GPIO_PIN_IRCUT_ON) && set_gpio_direction(GPIO_PIN_IRCUT_ON, OUT))) {
        syslog(LOG_ERR, "Failed to initialize GPIO%d", GPIO_PIN_IRCUT_ON);

        return 0;
    }

    if (!(is_gpio_active(GPIO_PIN_IRCUT_OFF) || export_gpio(GPIO_PIN_IRCUT_OFF) && set_gpio_direction(GPIO_PIN_IRCUT_OFF, OUT))) {
        syslog(LOG_ERR, "Failed to initialize GPIO%d", GPIO_PIN_IRCUT_OFF);

        return 0;
    }

    return 1;
}

int get_ir_cut(void)
{
    if (!initialize_ir_cut()) {
        return 0;
    }

    int state_on = read_gpio(GPIO_PIN_IRCUT_ON);
    int state_off = read_gpio(GPIO_PIN_IRCUT_OFF);

    return state_on == 1 && state_off == 0;
}

int set_ir_cut(int state)
{
    if (!initialize_ir_cut()) {
        return 0;
    }

    return write_gpio(GPIO_PIN_IRCUT_ON, !!state) && write_gpio(GPIO_PIN_IRCUT_OFF, !state);
}
