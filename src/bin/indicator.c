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
            case 'd': return !set_blue_led(0);
            case 'e': return !set_blue_led(1);
            case 's': return !get_blue_led();
            default: return 1;
        }
    }
}
