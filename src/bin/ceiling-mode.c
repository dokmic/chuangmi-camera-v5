#include <getopt.h>

#include "isp328.h"

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
            case 'd': return !(flip_mode_set(0) && mirror_mode_set(0));
            case 'e': return !(flip_mode_set(1) && mirror_mode_set(1));
            case 's': return !(flip_mode_get() && mirror_mode_get());
            default: return 1;
        }
    }
}
