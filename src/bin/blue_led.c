#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <popt.h>


#include "led.h"


struct CommandLineArguments
{
    unsigned int enable;
    unsigned int disable;
    unsigned int status;
} cli = {0, 0, 0};


int main(int argc, char *argv[])
{
    poptContext pc;
    struct poptOption po[] = {
        {"enable",  'e', POPT_ARG_NONE, &cli.enable,  0, "Enable the blue led",             "Enable"},
        {"disable", 'd', POPT_ARG_NONE, &cli.disable, 0, "Disable the blue led",            "Disable"},
        {"status",  's', POPT_ARG_NONE, &cli.status,  0, "Retrieve the status of the led",  "Led Status"},
        POPT_AUTOHELP
        {NULL}
    };

    pc = poptGetContext(NULL, argc, (const char **)argv, po, 0);
    poptSetOtherOptionHelp(pc, "[ARG...]");

    if (argc < 2) {
        poptPrintUsage(pc, stderr, 0);
        exit(1);
    }

    int val;
    while ((val = poptGetNextOpt(pc)) >= 0) {
    }

    if (val != -1) {
        fprintf(stderr, "%s: %s\n", poptBadOption(pc, POPT_BADOPTION_NOALIAS), poptStrerror(val));
        return 1;
    }

    if ((cli.enable + cli.disable + cli.status > 1)) {
        poptPrintUsage(pc, stderr, 0);
        exit(0);
    }

    if (cli.enable)
        return !blue_led_set(1);

    else if (cli.disable)
        return !blue_led_set(0);

    else if (cli.status)
        return !blue_led_get();

    else {
        poptPrintUsage(pc, stderr, 0);
        return 0;
    }
}
