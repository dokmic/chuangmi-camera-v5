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

void destroy_isp328(void)
{
    close(isp328_fd);
}

int initialize_isp328(void)
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

    atexit(destroy_isp328);

    return 1;
}

int get_flip_mode(void)
{
    if (!initialize_isp328()) {
        return 0;
    }

    int state;
    if (ioctl(isp328_fd, ISP_IOC_GET_SENSOR_FLIP, &state) < 0) {
        syslog(LOG_ERR, "Failed to get the flip mode");

        return 0;
    }

    return state;
}

int set_flip_mode(int state)
{
    if (!initialize_isp328()) {
        return 0;
    }

    int value = !!state;
    ioctl(isp328_fd, ISP_IOC_SET_SENSOR_FLIP, &value);

    return 1;
}

int get_mirror_mode(void)
{
    if (!initialize_isp328()) {
        return 0;
    }

    int state;
    if (ioctl(isp328_fd, ISP_IOC_GET_SENSOR_MIRROR, &state) < 0) {
        syslog(LOG_ERR, "Failed to get the mirror mode");

        return 0;
    }

    return state;
}

int set_mirror_mode(int state)
{
    if (!initialize_isp328()) {
        return 0;
    }

    int value = !!state;
    ioctl(isp328_fd, ISP_IOC_SET_SENSOR_MIRROR, &value);

    return 1;
}

int get_night_mode(void)
{
    if (!initialize_isp328()) {
        return 0;
    }

    int state;
    if (ioctl(isp328_fd, ISP_IOC_GET_MODE_NIGHT, &state) < 0) {
        syslog(LOG_ERR, "Failed to get the night mode");

        return 0;
    }

    return state;
}

int set_night_mode(int state)
{
    if (!initialize_isp328()) {
        return 0;
    }

    int value = !!state;
    ioctl(isp328_fd, ISP_IOC_SET_MODE_NIGHT, &value);

    return 1;
}

unsigned int get_light_info(void)
{
    if (!initialize_isp328()) {
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
