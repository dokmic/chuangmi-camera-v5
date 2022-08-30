#include <stdio.h>
#include <string.h>

#include "gpio.h"
#include "isp328.h"
#include "led.h"
#include "pwm.h"

#define MAX_COMMAND_SIZE 50

int get_ceiling_mode()
{
    return get_flip_mode() && get_mirror_mode();
}

int set_ceiling_mode(int state)
{
    return set_flip_mode(state) && set_mirror_mode(state);
}

static struct command {
    char *signature;
    int (*fn)();
    int arg;
} commands[] = {
    {"ir cut enable", &set_ir_cut, 1},
    {"ir cut disable", &set_ir_cut, 0},
    {"ir cut status", &get_ir_cut},
    {"led blue enable", &set_blue_led, 1},
    {"led blue disable", &set_blue_led, 0},
    {"led blue status", &get_blue_led},
    {"led ir enable", &set_ir_led, 1},
    {"led ir disable", &set_ir_led, 0},
    {"led ir status", &get_ir_led},
    {"led yellow enable", &set_yellow_led, 1},
    {"led yellow disable", &set_yellow_led, 0},
    {"led yellow status", &get_yellow_led},
    {"mode ceiling enable", &set_ceiling_mode, 1},
    {"mode ceiling disable", &set_ceiling_mode, 0},
    {"mode ceiling status", &get_ceiling_mode},
    {"mode flip enable", &set_flip_mode, 1},
    {"mode flip disable", &set_flip_mode, 0},
    {"mode flip status", &get_flip_mode},
    {"mode mirror enable", &set_mirror_mode, 1},
    {"mode mirror disable", &set_mirror_mode, 0},
    {"mode mirror status", &get_mirror_mode},
    {"mode night enable", &set_night_mode, 1},
    {"mode night disable", &set_night_mode, 0},
    {"mode night status", &get_night_mode},
};

int main(int argc, char *argv[])
{
    char command[MAX_COMMAND_SIZE + 1] = "";
    for (int i = 1; i < argc && strlen(command) < MAX_COMMAND_SIZE; i++) {
        if (i > 1) {
            strcat(command, " ");
        }

        strncat(command, argv[i], MAX_COMMAND_SIZE - strlen(command));
    }

    for (int i = 0; i < sizeof(commands) / sizeof(struct command); i++) {
        if (strcmp(command, commands[i].signature) == 0) {
            return !commands[i].fn(commands[i].arg);
        }
    }

    printf("Unknown command: %s\n", command);

    return 255;
}
