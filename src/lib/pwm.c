#include "pwm.h"

#define PWM_IOC_MAGIC               'p'
#define PWM_IOCTL_REQUEST           _IOW(PWM_IOC_MAGIC, 1, int)
#define PWM_IOCTL_START             _IOW(PWM_IOC_MAGIC, 2, int)
#define PWM_IOCTL_STOP              _IOW(PWM_IOC_MAGIC, 3, int)
#define PWM_IOCTL_GET_INFO          _IOWR(PWM_IOC_MAGIC, 4, pwm_info_t)
#define PWM_IOCTL_SET_CLKSRC        _IOW(PWM_IOC_MAGIC, 5, pwm_info_t)
#define PWM_IOCTL_SET_FREQ          _IOW(PWM_IOC_MAGIC, 6, pwm_info_t)
#define PWM_IOCTL_SET_DUTY_STEPS    _IOW(PWM_IOC_MAGIC, 7, pwm_info_t)
#define PWM_IOCTL_SET_DUTY_RATIO    _IOW(PWM_IOC_MAGIC, 8, pwm_info_t)
#define PWM_IOCTL_SET_MODE          _IOW(PWM_IOC_MAGIC, 9, pwm_info_t)
#define PWM_IOCTL_ENABLE_INTERRUPT  _IOW(PWM_IOC_MAGIC, 10, int)
#define PWM_IOCTL_DISABLE_INTERRUPT _IOW(PWM_IOC_MAGIC, 11, int)
#define PWM_IOCTL_ALL_START         _IO(PWM_IOC_MAGIC, 12)
#define PWM_IOCTL_ALL_STOP          _IO(PWM_IOC_MAGIC, 13)
#define PWM_IOCTL_UPDATE            _IOW(PWM_IOC_MAGIC, 14, int)
#define PWM_IOCTL_ALL_UPDATE        _IO(PWM_IOC_MAGIC, 15)
#define PWM_IOCTL_RELEASE           _IOW(PWM_IOC_MAGIC, 16, int)
#define PWM_IOC_MAXNR               16

#define PWM_DEVICE_NAME "/dev/ftpwmtmr010"

enum pwm_set_mode {
    PWM_ONESHOT,
    PWM_INTERVAL,
    PWM_REPEAT,
    PWM_PATTERN,
};

typedef struct pwm_info {
    unsigned int id;
    unsigned int clksrc;
    enum pwm_set_mode mode;
    unsigned int freq;
    unsigned int duty_steps;
    unsigned int duty_ratio;
    unsigned int pattern[4];
    int intr_cnt;
    unsigned short repeat_cnt;
    unsigned char pattern_len;
} pwm_info_t;

static int pwm_fd = -1;
static pwm_info_t pwm[2];

void destroy_pwm(void)
{
    close(pwm_fd);
}

int initialize_pwm(void)
{
    system("modprobe ftpwmtmr010");

    if ((pwm_fd = open(PWM_DEVICE_NAME, O_RDWR)) < 0) {
        syslog(LOG_ERR, "Failed to open %s", PWM_DEVICE_NAME);

        return 0;
    }

    memset(&pwm[0], 0, sizeof(pwm_info_t));

    pwm[0].clksrc = 1;
    pwm[0].mode = PWM_INTERVAL;
    pwm[0].duty_steps = 0xff;
    pwm[0].duty_ratio = 0x7f;
    pwm[0].intr_cnt = 1;
    pwm[0].repeat_cnt = 0x7f;

    memcpy(&pwm[1], &pwm[0], sizeof(pwm_info_t));

    int i;
    for (i = 0; i <= 1; i++) {
        pwm[i].id = i;
        ioctl(pwm_fd, PWM_IOCTL_REQUEST, &pwm[i].id);
        ioctl(pwm_fd, PWM_IOCTL_SET_CLKSRC, &pwm[i]);
        ioctl(pwm_fd, PWM_IOCTL_SET_MODE, &pwm[i]);
        ioctl(pwm_fd, PWM_IOCTL_UPDATE, &pwm[i].id);
        ioctl(pwm_fd, PWM_IOCTL_SET_DUTY_STEPS, &pwm[i]);
    }

    pwm[1].freq = 15000000; // enable clock for MS41909

    ioctl(pwm_fd, PWM_IOCTL_SET_FREQ, &pwm[1]);
    ioctl(pwm_fd, PWM_IOCTL_UPDATE, &pwm[1].id);
    ioctl(pwm_fd, PWM_IOCTL_START, &pwm[1].id);

    atexit(destroy_pwm);

    return 1;
}

int get_ir_led(void)
{
    if (!initialize_pwm()) {
        return 0;
    }

    ioctl(pwm_fd, PWM_IOCTL_GET_INFO, &pwm[0]);

    return pwm[0].duty_ratio > 0;
}

int set_ir_led(int value)
{
    if (!initialize_pwm()) {
        return 0;
    }

    pwm[0].duty_ratio = !!value * 0xff;
    ioctl(pwm_fd, PWM_IOCTL_SET_DUTY_RATIO, &pwm[0]);
    ioctl(pwm_fd, PWM_IOCTL_UPDATE, &pwm[0].id);
    ioctl(pwm_fd, PWM_IOCTL_START, &pwm[0].id);

    return 1;
}
