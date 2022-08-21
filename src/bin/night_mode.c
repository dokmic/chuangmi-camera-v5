#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <popt.h>

#include "isp328.h"


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
        {"enable",  'e', POPT_ARG_NONE, &cli.enable,  0, "Enable the night mode",      "Enable"},
        {"disable", 'd', POPT_ARG_NONE, &cli.disable, 0, "Disable the night mode",     "Disable"},
        {"status",  's', POPT_ARG_NONE, &cli.status,  0, "Retrieve the status",       "Status"},
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

    if (!cli.enable && !cli.disable && !cli.status) {
        poptPrintUsage(pc, stderr, 0);
        exit(1);
    }

    if ((cli.enable + cli.disable + cli.status > 1)) {
        poptPrintUsage(pc, stderr, 0);
        exit(1);
    }

    int success;
    if (cli.enable)
        success = night_mode_set(1);
    else if (cli.disable)
        success = night_mode_set(0);
    else if (cli.status)
        success = night_mode_get();

    return !success;
}
