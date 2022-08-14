#ifndef chuangmi_isp328_h
#define chuangmi_isp328_h

#define ISP_IOC_SENSOR 's'
#define ISP_IOC_GET_SENSOR_MIRROR       _IOR(ISP_IOC_SENSOR, 6, int)
#define ISP_IOC_SET_SENSOR_MIRROR       _IOW(ISP_IOC_SENSOR, 6, int)

#define ISP_IOC_GET_SENSOR_FLIP         _IOR(ISP_IOC_SENSOR, 7, int)
#define ISP_IOC_SET_SENSOR_FLIP         _IOW(ISP_IOC_SENSOR, 7, int)

#define ISP_DEV_NAME "/dev/isp328"

struct isp_light_info {
    int ev;
    int ir;
};

struct isp_light_info light_info = {0,0};
int isp_fd;

int isp328_init(void);
int isp328_end(void);

int mirrormode_on(void);
int mirrormode_off(void);
int mirrormode_status(void);

int nightmode_is_on(void);
int nightmode_update_values(void);

int nightmode_on(void);
int nightmode_off(void);
int nightmode_status(void);

int flipmode_on(void);
int flipmode_off(void);
int flipmode_status(void);

#endif
