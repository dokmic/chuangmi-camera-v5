#ifndef chuangmi_utils_h
#define chuangmi_utils_h

#define IN  0
#define OUT 1

#define LOW  0
#define HIGH 1

#define GPIO_BUFFER_MAX 3
#define GPIO_DIRECTION_MAX 35
#define GPIO_VALUE_MAX 30

int write_file(const char *file_path, char *content);
int read_int(const char *filename);

int gpio_export(int pin);
int gpio_unexport(int pin);
int gpio_direction(int pin, int dir);
int gpio_active(int pin);
int gpio_read(int pin);
int gpio_write(int pin, int value);

#endif
