#include <getopt.h>

#include "led.h"

static struct option options[] = {
    {"disable", no_argument, 0, 'd'},
    {"enable", no_argument, 0, 'e'},
    {"status", no_argument, 0, 's'},
};

int main(int argc, char *argv[])
{
    while (1) {
        int index;
        char command = getopt_long(argc, argv, "", options, &index);

        switch (command) {
            case 'd': return !blue_led_set(0);
            case 'e': return !blue_led_set(1);
            case 's': return !blue_led_get();
            default: return 1;
        }
    }
}
