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
            case 'd': return !(set_flip_mode(0) && set_mirror_mode(0));
            case 'e': return !(set_flip_mode(1) && set_mirror_mode(1));
            case 's': return !(get_flip_mode() && get_mirror_mode());
            default: return 1;
        }
    }
}
