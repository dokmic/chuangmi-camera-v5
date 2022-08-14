/*
 * mijia_ctrl
 * by cck56
 */

#include <assert.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/ioctl.h>

#include "chuangmi_isp328.h"

/*
 * Initialize the ISP328 device
 */
int isp328_init(void)
{
    // * Check if nightmode device can be accessed
    if (access(ISP_DEV_NAME, F_OK) < 0) {
        fprintf(stderr, "Error: Failed to access %s\n", ISP_DEV_NAME);
        return -1;
    }

    // * Open ISP328 file descriptor
    if ((isp_fd = open(ISP_DEV_NAME, O_RDWR)) < 0) {
        fprintf(stderr, "Error: Failed to open %s\n", ISP_DEV_NAME);
        return -1;
    }

    return 0;
}

/*
 * Return 0 if the isp328 device is initialized else -1
 */
int isp328_is_initialized(void)
{
    if (fcntl(isp_fd, F_GETFD) == -1) {
        fprintf(stderr, "Error: ISP328 Library is uninitialized.\n");
        return -1;
    }
    return 0;
}

/*
 * Close the ISP328 device
 */
int isp328_end(void)
{
    if (close(isp_fd) > 0)
        return 0;
    else
        return -1;
}

/*
 * Set mirror to a value (Valid: 1/0)
 */
int mirrormode_set(int value)
{
    if (isp328_is_initialized() < 0)
        return -1;

    if (value <= 1) {
        fprintf(stderr, "Setting mirror to %d\n", value);
        ioctl(isp_fd, ISP_IOC_SET_SENSOR_MIRROR, &value);
        return 0;
    } else {
        fprintf(stderr, "Failed to set mirror to %d\n", value);
        return -1;
    }
}

/*
 * Turn mirror on
 */
int mirrormode_on(void)
{
    return mirrormode_set(1);
}

/*
 * Turn mirror off
 */
int mirrormode_off(void)
{
    return mirrormode_set(0);
}

/*
 * Get the status for mirror
 */
int mirrormode_status(void)
{
    int mode;

    int ret = ioctl(isp_fd, ISP_IOC_GET_SENSOR_MIRROR, &mode);
    if (ret < 0) {
        fprintf(stdout, "Failed to retrieve the mirror mode\n");
        return -1;
    }

    fprintf(stdout, "%s\n", (mode == 1) ? "on" : "off");

    return 0;
}

/*
 * Get night mode state (Returns: 1/0)
 */
int nightmode_is_on(void)
{
    if (isp328_is_initialized() < 0)
       return -1;

    int mode;
    ioctl(isp_fd, _IOR(0x6d, 0x0a, int), &mode);

    if (mode == 1)
        return 1;

    return 0;
}

/*
 * Set night mode to a value (Valid: 1/0)
 */
int nightmode_set(int value)
{
    if (isp328_is_initialized() < 0)
        return -1;

    if ( value <= 1 ) {
        fprintf(stderr, "Setting nightmode to %d\n", value);
        ioctl(isp_fd, _IOW(0x6d, 0x0a, int), &value);
        return 0;
    } else
        return -1;
}

/*
 * Update the values in `isp_light_info` struct
 */
int nightmode_update_values(void)
{
    unsigned int converge = 0, ev = 0, sta_rdy = 0;
    unsigned int awb_sta[10];

    if (isp328_is_initialized() < 0)
        return -1;

    while (converge < 4) {
        ioctl(isp_fd, _IOR(0x65, 0x23, int), &converge);
        sleep(1);
    }

    ioctl(isp_fd, _IOR(0x65, 0x1f, int), &ev);

    while (sta_rdy != 0xf) {
        ioctl(isp_fd, _IOR(0x63, 0x09, int), &sta_rdy);
        usleep(1000);
    }

    ioctl(isp_fd, _IOR(0x68, 0x8a, int), awb_sta);

    light_info.ev = ev;
    light_info.ir = awb_sta[4] / 230400;

    return 0;
}

/*
 * Turn nightmode on
 */
int nightmode_on(void)
{
    return nightmode_set(1);
}

/*
 * Turn nightmode off
 */
int nightmode_off(void)
{
    return nightmode_set(0);
}

/*
 * Get the status for nightmode
 */
int nightmode_status(void)
{
    if (isp328_is_initialized() < 0)
        return -1;

    int state = nightmode_is_on();

    fprintf(stdout, "%s\n", (state == 1) ? "on" : "off");
    return 0;
}

/*
 * Set flip to a value (Valid: 1/0)
 */
int flipmode_set(int value)
{
    if (isp328_is_initialized() < 0)
        return -1;

    if (value <= 1) {
        fprintf(stderr, "Setting flip to %d\n", value);
        ioctl(isp_fd, ISP_IOC_SET_SENSOR_FLIP, &value);
        return 0;
    } else {
        fprintf(stderr, "Error: Cannot set flip to %d\n", value);
        return -1;
    }
}

/*
 * Turn flip on
 */
int flipmode_on(void)
{
    return flipmode_set(1);
}

/*
 * Turn flip off
 */
int flipmode_off(void)
{
    return flipmode_set(0);
}

/*
 * Get the status for flip
 */
int flipmode_status(void)
{
    int mode;

    int ret = ioctl(isp_fd, ISP_IOC_GET_SENSOR_FLIP, &mode);
    if (ret < 0) {
        fprintf(stdout, "Error: Retrieving flip mode values failed");
        return -1;
    }

    fprintf(stdout, "%s\n", (mode == 1) ? "on" : "off");

    return 0;
}
