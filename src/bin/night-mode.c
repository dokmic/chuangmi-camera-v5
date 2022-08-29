#include <getopt.h>
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>

#include "gpio.h"
#include "isp328.h"
#include "pwm.h"

static struct option options[] = {
    {"delay", required_argument, 0, 'd'},
    {"ev-on", required_argument, 0, 'e'},
    {"ev-off", required_argument, 0, 'f'},
    {"ir-on", required_argument, 0, 'i'},
    {"ir-off", required_argument, 0, 'j'},
};

static struct {
    int delay;

    int ev_on;
    int ev_off;

    int ir_on;
    int ir_off;
} arguments = {3, 30, 100, 90, 1000};

static struct {
    int ev;
    int ir;
} state = {0, 0};

void signal_handler(int signal)
{
    exit(0);
}

void toggle_night_mode(int state)
{
    set_night_mode(state);
    set_ir_cut(state);
    set_ir_led(state);
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
            case 'd':
                arguments.delay = atoi(optarg);
                break;
            case 'e':
                arguments.ev_on = atoi(optarg);
                break;
            case 'f':
                arguments.ev_off = atoi(optarg);
                break;
            case 'i':
                arguments.ir_on = atoi(optarg);
                break;
            case 'j':
                arguments.ir_off = atoi(optarg);
                break;
            default: return 1;
        }
    }

    signal(SIGINT, signal_handler);
    signal(SIGHUP, signal_handler);
    signal(SIGTERM, signal_handler);

    while (1) {
        unsigned int light_info = get_light_info();
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

        int night_mode = get_night_mode();

        if (ev < arguments.ev_on && ir > arguments.ir_on && !night_mode) {
            toggle_night_mode(1);
        } else if (ev > arguments.ev_off && ir < arguments.ir_off && night_mode) {
            toggle_night_mode(0);
        }

        sleep(arguments.delay);
    }
}
