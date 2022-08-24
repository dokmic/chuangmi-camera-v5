#include <getopt.h>
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>

#include "gpio.h"
#include "isp328.h"
#include "pwm.h"

static struct option options[] = {
    {"disable", no_argument, 0, 'd'},
    {"enable", no_argument, 0, 'e'},
    {"status", no_argument, 0, 's'},
    {"delay", required_argument, 0, 'h'},
    {"ir-on", required_argument, 0, 'i'},
    {"ir-off", required_argument, 0, 'j'},
    {"ev-on", required_argument, 0, 'k'},
    {"ev-off", required_argument, 0, 'l'},
};

static struct {
    int delay;

    int ir_on;
    int ir_off;

    int ev_on;
    int ev_off;
} arguments = {3, 90, 1000, 30, 100};

static struct {
    int ev;
    int ir;
} state = {0, 0};

void darkness_mode_set(int state)
{
    night_mode_set(state);
    ir_cut_set(state);
    ir_led_set(state);
}

void night_mode_auto(void)
{
    while (1) {
        unsigned int light_info = light_info_get();
        if (!light_info) {
            syslog(LOG_ERR, "Failed to get EV and IR");
            sleep(arguments.delay);
            continue;
        }

        int ev = light_info >> 16;
        int ir = light_info & 0xffff;

        if (state.ev == ev && state.ir == ir) {
            continue;
        }

        state.ev = ev;
        state.ir = ir;
        syslog(LOG_DEBUG, "EV=%d; IR=%d", ev ,ir);

        int night_mode = night_mode_get();

        if (ev < arguments.ev_on && ir > arguments.ir_on && !night_mode) {
            darkness_mode_set(1);
        } else if (ev > arguments.ev_off && ir < arguments.ir_off && night_mode) {
            darkness_mode_set(0);
        }

        sleep(arguments.delay);
    }
}

void signal_handler(int signal)
{
    exit(0);
}

int main(int argc, char *argv[])
{
    while (1) {
        int index;
        int command = getopt_long(argc, argv, "", options, &index);
        if (command == -1) {
            break;
        }

        switch (command) {
            case 'd': return !night_mode_set(0);
            case 'e': return !night_mode_set(1);
            case 's': return !night_mode_get();
            case 'h':
                arguments.delay = atoi(optarg);
                break;
            case 'i':
                arguments.ir_on = atoi(optarg);
                break;
            case 'j':
                arguments.ir_off = atoi(optarg);
                break;
            case 'k':
                arguments.ev_on = atoi(optarg);
                break;
            case 'l':
                arguments.ev_off = atoi(optarg);
                break;
            default: return 1;
        }
    }

    signal(SIGINT, signal_handler);
    signal(SIGHUP, signal_handler);
    signal(SIGTERM, signal_handler);
    night_mode_auto();

    return 0;
}
