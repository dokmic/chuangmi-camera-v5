#include "isp328.h"

#define ISP_IOC_MODE 'm'
#define ISP_IOC_SENSOR 's'

#define ISP_IOC_GET_FILTER_NIGHT _IOR(ISP_IOC_MODE, 10, int)
#define ISP_IOC_SET_FILTER_NIGHT _IOW(ISP_IOC_MODE, 10, int)

#define ISP_IOC_GET_FILTER_MIRROR _IOR(ISP_IOC_SENSOR, 6, int)
#define ISP_IOC_SET_FILTER_MIRROR _IOW(ISP_IOC_SENSOR, 6, int)

#define ISP_IOC_GET_FILTER_FLIP _IOR(ISP_IOC_SENSOR, 7, int)
#define ISP_IOC_SET_FILTER_FLIP _IOW(ISP_IOC_SENSOR, 7, int)

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

int get_flip_filter(void)
{
    if (!initialize_isp328()) {
        return 0;
    }

    int state;
    if (ioctl(isp328_fd, ISP_IOC_GET_FILTER_FLIP, &state) < 0) {
        syslog(LOG_ERR, "Failed to get the flip filter");

        return 0;
    }

    return state;
}

int set_flip_filter(int state)
{
    if (!initialize_isp328()) {
        return 0;
    }

    int value = !!state;
    ioctl(isp328_fd, ISP_IOC_SET_FILTER_FLIP, &value);

    return 1;
}

int get_mirror_filter(void)
{
    if (!initialize_isp328()) {
        return 0;
    }

    int state;
    if (ioctl(isp328_fd, ISP_IOC_GET_FILTER_MIRROR, &state) < 0) {
        syslog(LOG_ERR, "Failed to get the mirror filter");

        return 0;
    }

    return state;
}

int set_mirror_filter(int state)
{
    if (!initialize_isp328()) {
        return 0;
    }

    int value = !!state;
    ioctl(isp328_fd, ISP_IOC_SET_FILTER_MIRROR, &value);

    return 1;
}

int get_night_filter(void)
{
    if (!initialize_isp328()) {
        return 0;
    }

    int state;
    if (ioctl(isp328_fd, ISP_IOC_GET_FILTER_NIGHT, &state) < 0) {
        syslog(LOG_ERR, "Failed to get the night filter");

        return 0;
    }

    return state;
}

int set_night_filter(int state)
{
    if (!initialize_isp328()) {
        return 0;
    }

    int value = !!state;
    ioctl(isp328_fd, ISP_IOC_SET_FILTER_NIGHT, &value);

    return 1;
}
