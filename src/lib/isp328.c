#include "isp328.h"

#define ISP_IOC_MODE 'm'
#define ISP_IOC_SENSOR 's'

#define ISP_IOC_GET_MODE_NIGHT _IOR(ISP_IOC_MODE, 10, int)
#define ISP_IOC_SET_MODE_NIGHT _IOW(ISP_IOC_MODE, 10, int)

#define ISP_IOC_GET_SENSOR_MIRROR _IOR(ISP_IOC_SENSOR, 6, int)
#define ISP_IOC_SET_SENSOR_MIRROR _IOW(ISP_IOC_SENSOR, 6, int)

#define ISP_IOC_GET_SENSOR_FLIP _IOR(ISP_IOC_SENSOR, 7, int)
#define ISP_IOC_SET_SENSOR_FLIP _IOW(ISP_IOC_SENSOR, 7, int)

#define ISP_DEVICE_NAME "/dev/isp328"

static int isp328_fd = -1;

void isp328_destroy(void)
{
    close(isp328_fd);
}

int isp328_initialize(void)
{
    if (isp328_fd != -1 && fcntl(isp328_fd, F_GETFD) != -1) {
        return 1;
    }

    if (access(ISP_DEVICE_NAME, F_OK) < 0) {
        syslog(LOG_ERR, "Failed to access %s", ISP_DEVICE_NAME);

        return 0;
    }

    if ((isp328_fd = open(ISP_DEVICE_NAME, O_RDWR)) < 0) {
        syslog(LOG_ERR, "Failed to open %s", ISP_DEVICE_NAME);

        return 0;
    }

    atexit(isp328_destroy);

    return 1;
}

int flip_mode_get(void)
{
    if (!isp328_initialize()) {
        return 0;
    }

    int state;
    if (ioctl(isp328_fd, ISP_IOC_GET_SENSOR_FLIP, &state) < 0) {
        syslog(LOG_ERR, "Failed to get the flip mode");

        return 0;
    }

    return state;
}

int flip_mode_set(int state)
{
    if (!isp328_initialize()) {
        return 0;
    }

    int value = !!state;
    ioctl(isp328_fd, ISP_IOC_SET_SENSOR_FLIP, &value);

    return 1;
}

int mirror_mode_get(void)
{
    if (!isp328_initialize()) {
        return 0;
    }

    int state;
    if (ioctl(isp328_fd, ISP_IOC_GET_SENSOR_MIRROR, &state) < 0) {
        syslog(LOG_ERR, "Failed to get the mirror mode");

        return 0;
    }

    return state;
}

int mirror_mode_set(int state)
{
    if (!isp328_initialize()) {
        return 0;
    }

    int value = !!state;
    ioctl(isp328_fd, ISP_IOC_SET_SENSOR_MIRROR, &value);

    return 1;
}

int night_mode_get(void)
{
    if (!isp328_initialize()) {
        return 0;
    }

    int state;
    if (ioctl(isp328_fd, ISP_IOC_GET_MODE_NIGHT, &state) < 0) {
        syslog(LOG_ERR, "Failed to get the night mode");

        return 0;
    }

    return state;
}

int night_mode_set(int state)
{
    if (!isp328_initialize()) {
        return 0;
    }

    int value = !!state;
    ioctl(isp328_fd, ISP_IOC_SET_MODE_NIGHT, &value);

    return 1;
}

unsigned int light_info_get(void)
{
    if (!isp328_initialize()) {
        return 0;
    }

    unsigned int converge = 0, ev = 0, ir = 0, status_ready = 0;
    unsigned int awb_status[10];

    while (converge < 4) {
        ioctl(isp328_fd, _IOR(0x65, 0x23, int), &converge);
        sleep(1);
    }
    ioctl(isp328_fd, _IOR(0x65, 0x1f, int), &ev);

    while (status_ready != 0xf) {
        ioctl(isp328_fd, _IOR(0x63, 0x09, int), &status_ready);
        usleep(1000);
    }
    ioctl(isp328_fd, _IOR(0x68, 0x8a, int), awb_status);
    ir = awb_status[4] / 230400;

    return (ev << 16) | ir;
}
