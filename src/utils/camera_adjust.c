#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "chuangmi_isp328.h"


struct CommandLineArguments
{
    unsigned int get;
    unsigned int set;
    unsigned int type;
    unsigned int info;
    unsigned int json;
    unsigned int shell;
    unsigned int reset;
} cli = {0, 0, 0, 0, 0, 0, 0};


static void print_usage_and_exit(void)
{
    printf("Usage:\n");
    printf("   camera_adjust [-s|-g] -t [brightness|contrast|hue|saturation|denoise|sharpness]\n");
    printf(
        "\nAvailable options:\n"
        "  -s    set\n"
        "  -g    get\n"
        "  -t    type\n"
        "  -i    info\n"
        "  -j    info (in json)\n"
        "  -k    info (shell)\n"
        "  -r    reset settings\n"
        "\n\n"
        "Description:\n"
        "- Set: Set the value (0-255)\n"
        "- Get: Get the value\n"
        "- Type: The type of setting to get/set the value for\n"
        "\n"
    );

    exit(EXIT_FAILURE);
}


int main(int argc, char *argv[])
{
    int opt;

    char *setting;
    unsigned int value;

    while ((opt = getopt(argc, argv, "gjikrt:s:")) != -1) {
        switch (opt)
        {
            case 'g':
                cli.get = 1;
                break;
            case 's':
                cli.set = 1;
                value = atoi(optarg);
                break;
            case 't':
                cli.type = 1;
                setting = optarg;
                break;
            case 'i':
                cli.info = 1;
                break;
            case 'j':
                cli.json = 1;
                break;
            case 'k':
                cli.shell = 1;
                break;
            case 'r':
                cli.reset = 1;
                break;
            default:
                print_usage_and_exit();
                break;
        }
    }

    if (cli.get + cli.set + cli.info + cli.json + cli.shell + cli.reset == 0) {
        print_usage_and_exit();
    }

    if (cli.get + cli.set + cli.json + cli.info + cli.shell + cli.reset > 1) {
        fprintf(stderr, "Use either -j, -i, -k, -r, -g or -s but not more then one!\n");
        print_usage_and_exit();
    }

    if (isp328_init() < 0) {
        fprintf(stderr, "*** Error: ISP328 initialization failed\n");
        return EXIT_FAILURE;
    }

    if (cli.reset) {
        return reset_camera_adjustments();
    }

    if (cli.info)
        return print_camera_info();

    if (cli.json)
        return print_camera_info_json();

    if (cli.shell)
        return print_camera_info_shell();

    int success;
    if (strcmp(setting, "brightness") == 0) {
        if (cli.set == 1)
            success = brightness_set(value);
        else if (cli.get == 1)
            success = brightness_print();
    }
    else if (strcmp(setting, "contrast") == 0) {
        if (cli.set == 1)
            success = contrast_set(value);
        else if (cli.get == 1)
            success = contrast_print();
    }
    else if (strcmp(setting, "hue") == 0) {
        if (cli.set == 1)
            success = hue_set(value);
        else if (cli.get == 1)
            success = hue_print();
    }
    else if (strcmp(setting, "saturation") == 0) {
        if (cli.set == 1)
            success = saturation_set(value);
        else if (cli.get == 1)
            success = saturation_print();
    }
    else if (strcmp(setting, "denoise") == 0) {
        if (cli.set == 1)
            success = denoise_set(value);
        else if (cli.get == 1)
            success = denoise_print();
    }
    else if (strcmp(setting, "sharpness") == 0) {
        if (cli.set == 1)
            success = sharpness_set(value);
        else if (cli.get == 1)
            success = sharpness_print();
    }
    else {
        fprintf(stderr, "Options for -t are: [brightness|contrast|hue|saturation|denoise|sharpness]!\n");
        print_usage_and_exit();
    }

    isp328_end();
    return success;
}
