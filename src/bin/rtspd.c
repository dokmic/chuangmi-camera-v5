/* @file rtspd.c
 *  Simple RTSP server demo
 * Copyright (C) 2013 GM Corp. (http://www.grain-media.com)
 *
 * $Revision: 1.5 $
 * $Date: 2014/12/30 05:37:57 $
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <syslog.h>

#include "gmlib.h"
#include "librtsp.h"

#define DVR_ENC_EBST_ENABLE      0x55887799
#define DVR_ENC_EBST_DISABLE     0

#define ENC_TYPE_H264            0
#define ENC_TYPE_MPEG4           1
#define ENC_TYPE_MJPEG           2

#define CAP_CH_NUM               1
#define RTSP_NUM_PER_CAP         4
#define CAP_PATH_NUM             4
#define ENC_TRACK_NUM            4

#define SDPSTR_MAX               128
#define SR_MAX                   64
#define VQ_MAX                   (SR_MAX)
#define VQ_LEN                   5
#define AQ_MAX                   64            // * 1 MP2 and 1 AMR for live streaming, another 2 for file streaming.
#define AQ_LEN                   2             // * 1 MP2 and 1 AMR for live streaming, another 2 for file streaming.
#define AV_NAME_MAX              127

#define RTP_HZ                   90000

#define ERR_GOTO(x, y)           do { ret = x; goto y; } while(0)
#define MUTEX_FAILED(x)          (x == ERR_MUTEX)

#define NONE_BS_EVENT            0
#define START_BS_EVENT           1
#define STOP_BS_EVENT            2

#define CHECK_CHANNUM_AND_SUBNUM(ch_num, sub_num)    \
    do {    \
        if ((ch_num >= CAP_CH_NUM || ch_num < 0) || \
            (sub_num >= RTSP_NUM_PER_CAP || sub_num < 0)) {    \
            log_error("%s: ch_num=%d, sub_num=%d error!",__FUNCTION__, ch_num, sub_num);    \
            return -1; \
        }    \
    } while(0)    \

#define log_info(...) syslog(LOG_INFO, __VA_ARGS__)
#define log_error(...) syslog(LOG_ERR, __VA_ARGS__)
#define log_fatal(...) syslog(LOG_CRIT, __VA_ARGS__)

typedef struct {
    void *obj;
    gm_cap_attr_t cap_attr;
    gm_3dnr_attr_t dnr_attr;
} gm_cap_info_t;

typedef struct {
    void *obj;
    int enc_type;
    union {
        gm_h264e_attr_t h264e_attr;
        gm_mpeg4e_attr_t mpeg4e_attr;
        gm_mjpege_attr_t mjpege_attr;
    } codec;
} gm_enc_info_t;

typedef struct {
    gm_cap_info_t cap;
    gm_enc_info_t enc[ENC_TRACK_NUM];
    void *bindfd[ENC_TRACK_NUM];
} gm_enc_t;

void *enc_groupfd;
gm_enc_t enc_param[CAP_CH_NUM][CAP_PATH_NUM];

typedef int (*open_container_fn)(int ch_num, int sub_num);
typedef int (*close_container_fn)(int ch_num, int sub_num);

typedef enum st_opt_type {
    OPT_NONE=0,
    RTSP_LIVE_STREAMING,
} opt_type_t;

typedef struct st_vbs {
    int enabled;                  // * DVR_ENC_EBST_ENABLE: enabled, DVR_ENC_EBST_DISABLE: disabled
    int enc_type;                 // * 0:ENC_TYPE_H264, 1:ENC_TYPE_MPEG4, 2:ENC_TYPE_MJPEG
} vbs_t;

typedef struct st_priv_vbs {
    char sdpstr[SDPSTR_MAX];
    int qno;
    int offs;
    int len;
    unsigned int tv_ms;
    int cap_ch;
    int cap_path;
    int rec_track;
    char *bs_buf;
    unsigned int bs_buf_len;
    pthread_mutex_t priv_vbs_mutex;
} priv_vbs_t;

typedef struct st_bs {
    int event;                    // * Config change please set 1 for enqueue_thread to config this
    int enabled;                  // * DVR_ENC_EBST_ENABLE: enabled, DVR_ENC_EBST_DISABLE: disabled
    opt_type_t opt_type;          // * 1:rtsp_live_streaming, 2: file_avi_recording 3:file_h264_recording
    vbs_t video;                  // * VIDEO, 0: main-bitstream, 1: sub1-bitstream, 2:sub2-bitstream
} avbs_t;

typedef struct st_priv_bs {
    int play;
    int congest;
    int sr;
     char name[AV_NAME_MAX];
    open_container_fn open;
    close_container_fn close;
    priv_vbs_t video;             // * VIDEO, 0: main-bitstream, 1: sub1-bitstream, 2:sub2-bitstream
} priv_avbs_t;

typedef struct st_av {
    // * Public data
    avbs_t bs[RTSP_NUM_PER_CAP];  // * VIDEO, 0: main-bitstream, 1: sub1-bitstream, 2:sub2-bitstream

    // * Update data
    pthread_mutex_t ubs_mutex;

    // * Private data
    int enabled;                  // * DVR_ENC_EBST_ENABLE: enabled, DVR_ENC_EBST_DISABLE: disabled
    priv_avbs_t priv_bs[RTSP_NUM_PER_CAP];
} av_t;

pthread_t enqueue_thread_id   = 0;
pthread_t encode_thread_id    = 0;

unsigned int sys_tick         = 0;
struct timeval sys_sec        = {-1, -1};
int sys_port                  = 554;
char *ipptr                   = NULL;

static int rtspd_sysinit      = 0;
static int rtspd_set_event    = 0;
static int rtspd_avail_ch     = 0;

pthread_mutex_t stream_queue_mutex;
av_t enc[CAP_CH_NUM];
gm_system_t gm_system;

void *groupfd;                    // * Return of gm_new_groupfd()
void *bindfd;                     // * Return of gm_bind()
void *capture_object;
void *encode_object;
void *sub_enc_object;             // * Create encoder object (scaler)
void *sub_bindfd;                 // * Create encoder object (scaler) bind

struct CommandLineArguments {
    int framerate;
    int height;
    int width;
    int bitrate;
    int bitrateMode;
    int encoderType;
    char *user;
    char *password;
} cliArgs;

static char *rtsp_enc_type_str[] = {
    "H264 ",
    "MPEG4",
    "MJPEG"
};

static int rtsp_use_auth = 0;

static int do_queue_alloc(int type)
{
    int rc;
    do {
        rc = stream_queue_alloc(type);
    } while MUTEX_FAILED(rc);

    return rc;
}

static unsigned int get_tick_gm(unsigned int tv_ms)
{
    sys_tick = tv_ms*(RTP_HZ / 1000);
    return sys_tick;
}

static int convert_gmss_media_type(int type)
{
    int media_type;

    switch(type) {
        case ENC_TYPE_H264:
            media_type = GM_SS_TYPE_H264;
            break;
        case ENC_TYPE_MPEG4:
            media_type = GM_SS_TYPE_MP4;
            break;
        case ENC_TYPE_MJPEG:
            media_type = GM_SS_TYPE_MJPEG;
            break;
        default:
            media_type  = -1;
            log_error("convert_gmss_media_type: type=%d, error!", type);
            break;
    }
    return media_type;
}

static int open_live_streaming(int ch_num, int sub_num)
{
    int media_type;
    avbs_t *b;
    priv_avbs_t *pb;
    char livename[64];

    CHECK_CHANNUM_AND_SUBNUM(ch_num, sub_num);
    b = &enc[ch_num].bs[sub_num];
    pb = &enc[ch_num].priv_bs[sub_num];
    media_type = convert_gmss_media_type(b->video.enc_type);
    pb->video.qno = do_queue_alloc(media_type);

    sprintf(livename, "live/ch%02d_%d", ch_num, sub_num);
    pb->sr = stream_reg(livename, pb->video.qno, pb->video.sdpstr, 0, 0, 1, 0, 0, 0, 0, 0, 0);

    if (pb->sr < 0)
        log_error("open_live_streaming: ch_num=%d, sub_num=%d setup error", ch_num, sub_num);

    // * Enable authentication for the stream if the username and password are set
    if (rtsp_use_auth == 1) {
        stream_authorization(pb->sr, cliArgs.user, cliArgs.password);
    }

    strcpy(pb->name, livename);

    return 0;
}

#define TIMEVAL_DIFF(start, end) (((end.tv_sec)-(start.tv_sec))*1000000+((end.tv_usec)-(start.tv_usec)))
static int write_rtp_frame_ext(int ch_num, int sub_num, void *data, int data_len, unsigned int tv_ms)
{
    int ret, media_type;
    avbs_t *b;
    priv_avbs_t *pb;
    gm_ss_entity entity;
    struct timeval curr_tval;
    static struct timeval err_print_tval;

    pb = &enc[ch_num].priv_bs[sub_num];
    b  = &enc[ch_num].bs[sub_num];

    if ( pb->play == 0 || (b->event != NONE_BS_EVENT) ) {
        ret = 1;
        goto exit_free_as_buf;
    }

    entity.data = (char *) data;
    entity.size = data_len;
    entity.timestamp = get_tick_gm(tv_ms);
    media_type = convert_gmss_media_type(b->video.enc_type);
    pthread_mutex_lock(&stream_queue_mutex);
    ret = stream_media_enqueue(media_type, pb->video.qno, &entity);
    pthread_mutex_unlock(&stream_queue_mutex);

    if ( ret < 0 ) {
        gettimeofday(&curr_tval, NULL );

        if ( ret == ERR_FULL) {
            pb->congest = 1;

            if ( TIMEVAL_DIFF(err_print_tval, curr_tval) > 5000000 )
                log_error("ext enqueue queue ch_num=%d, sub_num=%d full", ch_num, sub_num);
        }
        else if ((ret != ERR_NOTINIT)&& (ret != ERR_MUTEX) && (ret != ERR_NOTRUN)) {

            if (TIMEVAL_DIFF(err_print_tval, curr_tval) > 5000000)
                log_error("ext enqueue queue ch_num=%d, sub_num=%d error %d", ch_num, sub_num, ret);
        }

        if ( TIMEVAL_DIFF(err_print_tval, curr_tval) > 5000000) {
            log_error("ext enqueue queue ch_num=%d, sub_num=%d error %d", ch_num, sub_num, ret);
            gettimeofday(&err_print_tval, NULL );
        }
        goto exit_free_audio_buf;
    }

    return 0;

exit_free_audio_buf:
    //put_video_frame(pb->video.qno, fs);
exit_free_as_buf:
    //free_bs_data(ch_num, sub_num, q);
    return 1;
}

static int close_live_streaming(int ch_num, int sub_num)
{
    avbs_t *b;
    priv_avbs_t *pb;
    int ret = 0;

    CHECK_CHANNUM_AND_SUBNUM(ch_num, sub_num);
    b = &enc[ch_num].bs[sub_num];
    pb = &enc[ch_num].priv_bs[sub_num];

    if (pb->sr >= 0) {
        ret = stream_dereg(pb->sr, 1);

        if (ret < 0)
            goto err_exit;

        pb->sr = -1;
        pb->video.qno = -1;
        pb->play = 0;
    }

err_exit:
    if (ret < 0)
        log_error("%s: stream_dereg(%d) err %d", __func__, pb->sr, ret);

    return ret;
}

int open_bs(int ch_num, int sub_num)
{
    avbs_t *b;
    priv_avbs_t *pb;

    CHECK_CHANNUM_AND_SUBNUM(ch_num, sub_num);
    pb = &enc[ch_num].priv_bs[sub_num];
    b = &enc[ch_num].bs[sub_num];

    enc[ch_num].enabled = DVR_ENC_EBST_ENABLE;
    enc[ch_num].bs[sub_num].enabled = DVR_ENC_EBST_ENABLE;
    enc[ch_num].bs[sub_num].video.enabled = DVR_ENC_EBST_ENABLE;

    switch (b->opt_type) {
        case RTSP_LIVE_STREAMING:
            pb->open = open_live_streaming;
            pb->close = close_live_streaming;
            break;
        case OPT_NONE:
        default:
            break;
    }

    return 0;
}

int close_bs(int ch_num, int sub_num)
{
    av_t *e;
    int sub, is_close_channel = 1;

    CHECK_CHANNUM_AND_SUBNUM(ch_num, sub_num);
    e = &enc[ch_num];

    e->bs[sub_num].video.enabled = DVR_ENC_EBST_DISABLE;
    e->bs[sub_num].enabled = DVR_ENC_EBST_DISABLE;

    for (sub = 0; sub < RTSP_NUM_PER_CAP; sub++) {
        if (e->bs[sub].video.enabled == DVR_ENC_EBST_ENABLE) {
            is_close_channel = 0;
            break;
        }
    }

    if (is_close_channel == 1)
        enc[ch_num].enabled = DVR_ENC_EBST_DISABLE;

    return 0;
}

static int bs_check_event(void)
{
    int ch_num, sub_num, ret = 0;
    avbs_t *b;

    for (ch_num = 0; ch_num < CAP_CH_NUM; ch_num++) {
        for (sub_num = 0; sub_num < RTSP_NUM_PER_CAP; sub_num++) {
            b = &enc[ch_num].bs[sub_num];
            if (b->event != NONE_BS_EVENT) {
                ret = 1;
                break;
            }
        }
    }

    return ret;
}

void bs_new_event(void)
{
    int ch_num, sub_num;
    avbs_t *b;
    priv_avbs_t *pb;

    if (bs_check_event() == 0) {
        rtspd_set_event = 0;
        return;
    }

    for (ch_num = 0; ch_num < CAP_CH_NUM; ch_num++) {
        pthread_mutex_lock(&enc[ch_num].ubs_mutex);

        for (sub_num = 0; sub_num < RTSP_NUM_PER_CAP; sub_num++) {
            b = &enc[ch_num].bs[sub_num];
            pb = &enc[ch_num].priv_bs[sub_num];
            switch (b->event) {

                case START_BS_EVENT:
                    open_bs(ch_num, sub_num);
                    if (pb->open) pb->open(ch_num, sub_num);
                    b->event = NONE_BS_EVENT;
                    break;

                case STOP_BS_EVENT:
                    pb->open = NULL;
                    if (pb->close) {
                        pb->close(ch_num, sub_num);
                        pb->close = NULL;
                        close_bs(ch_num, sub_num);
                    }
                    b->event = NONE_BS_EVENT;
                    break;

                default:
                    break;
            }
        }
        pthread_mutex_unlock(&enc[ch_num].ubs_mutex);
    }
}

int env_set_bs_new_event(int ch_num, int sub_num, int event)
{
    avbs_t *b;
    int ret = 0;

    CHECK_CHANNUM_AND_SUBNUM(ch_num, sub_num);
    b = &enc[ch_num].bs[sub_num];

    switch (event) {
        case START_BS_EVENT:
            if (b->opt_type == OPT_NONE)
                goto err_exit;

            if (b->enabled == DVR_ENC_EBST_ENABLE) {
                log_error("Already enabled: ch_num=%d, sub_num=%d", ch_num, sub_num);
                ret = -1;
                goto err_exit;
            }
            break;
        case STOP_BS_EVENT:
            if (b->enabled != DVR_ENC_EBST_ENABLE) {
                log_error("Already disabled: ch_num=%d, sub_num=%d", ch_num, sub_num);
                ret = -1;
                goto err_exit;
            }
            break;
        default:
            log_error("env_set_bs_new_event: ch_num=%d, sub_num=%d, event=%d, error", ch_num, sub_num, event);
            ret = -1;
            goto err_exit;
    }
    b->event = event;
    rtspd_set_event = 1;

err_exit:
    return ret;
}

int set_poll_event(void)
{
    int ch_num, sub_num, ret = -1;
    av_t *e;
    avbs_t *b;

    for (ch_num = 0; ch_num < CAP_CH_NUM; ch_num++) {
        e = &enc[ch_num];

        if (e->enabled != DVR_ENC_EBST_ENABLE)
            continue;

        for (sub_num = 0; sub_num < RTSP_NUM_PER_CAP; sub_num++) {
            b = &e->bs[sub_num];
            if (b->video.enabled == DVR_ENC_EBST_ENABLE)
                ret = 0;
        }
    }

    return ret;
}

void get_enc_res(gm_enc_info_t *enc, int *enc_type, int *width, int *height)
{
    int w, h;
    gm_h264e_attr_t *h264e_attr;
    gm_mpeg4e_attr_t *mpeg4e_attr;
    gm_mjpege_attr_t *mjpege_attr;

    switch (enc->enc_type) {
        case ENC_TYPE_H264:
            h264e_attr  = &enc->codec.h264e_attr;
            w           = h264e_attr->dim.width;
            h           = h264e_attr->dim.height;
            break;

        case ENC_TYPE_MPEG4:
            mpeg4e_attr = &enc->codec.mpeg4e_attr;
            w           = mpeg4e_attr->dim.width;
            h           = mpeg4e_attr->dim.height;
            break;

        case ENC_TYPE_MJPEG:
            mjpege_attr = &enc->codec.mjpege_attr;
            w           = mjpege_attr->dim.width;
            h           = mjpege_attr->dim.height;
            break;
    }

    if (enc_type)
        *enc_type = enc->enc_type;

    if (width)
        *width = w;

    if (height)
        *height = h;
}

#define PRINT_INTERVAL_MS 5000
static unsigned int frame_counts[CAP_CH_NUM][RTSP_NUM_PER_CAP] = {{0}};
static unsigned int rec_bs_len[CAP_CH_NUM][RTSP_NUM_PER_CAP]   = {{0}};
static void print_enc_average(int ch_num, int sub_num, int bs_len, struct timeval *cur_timeval)
{
    int enc_type, w, h;
    static struct timeval last_timeval;
    static unsigned int total_ms, print_init = 0;
    unsigned int diff_ms, i, j;
    char res_str[20];
    priv_avbs_t *pb;
    gm_enc_info_t *gm_enc;

    frame_counts[ch_num][sub_num]++;
    rec_bs_len[ch_num][sub_num] += bs_len;

    if (print_init == 0) {
        last_timeval.tv_sec = cur_timeval->tv_sec;
        last_timeval.tv_usec = cur_timeval->tv_usec;
        print_init = 1;
        total_ms = 0;
        return;
    }

    // * Get diff time
    if (cur_timeval->tv_sec > last_timeval.tv_sec) {
        diff_ms = 1000 + (cur_timeval->tv_usec / 1000) - (last_timeval.tv_usec / 1000);
        diff_ms += (cur_timeval->tv_sec - last_timeval.tv_sec - 1) * 1000;
    } else {
        diff_ms = (cur_timeval->tv_usec - last_timeval.tv_usec) / 1000;
    }

    total_ms += diff_ms;

    // * Show statistic
    if (total_ms >= PRINT_INTERVAL_MS) {
        for (i = 0; i < CAP_CH_NUM; i++) {
            for (j = 0; j < RTSP_NUM_PER_CAP; j++) {
                if (frame_counts[i][j] == 0)
                    continue;

                pb = &enc[i].priv_bs[j];
                gm_enc = &enc_param[pb->video.cap_ch][pb->video.cap_path].enc[pb->video.rec_track];
                get_enc_res(gm_enc, &enc_type, &w, &h);
                sprintf(res_str, "%dx%d", w, h);

                log_info("path=/live/ch%02d_%d cap=%d_%d size=%s enc=%s fps=%d.%d kbps=%d",
                        i,
                        j,
                        pb->video.cap_ch,
                        pb->video.cap_path,
                        res_str,
                        rtsp_enc_type_str[enc_type],
                        (frame_counts[i][j] * 1000 / total_ms),
                        (frame_counts[i][j] * 100000 / total_ms) % 100,
                        (rec_bs_len[i][j] * 8 / 1024) * 1000 / total_ms
                );

                frame_counts[i][j] = 0;
                rec_bs_len[i][j] = 0;
            }
        }
        total_ms = 0;
    }

    last_timeval.tv_sec = cur_timeval->tv_sec;
    last_timeval.tv_usec = cur_timeval->tv_usec;
}

#define POLL_WAIT_TIME 15000
static unsigned int poll_wait_time = 0;
static void env_release_resources(void)
{
    int ret, ch_num;
    av_t *e;

    if ((ret = stream_server_stop()))
        log_error("stream_server_stop() error %d", ret);

    for (ch_num = 0; ch_num < CAP_CH_NUM; ch_num++) {
        e = &enc[ch_num];
        pthread_mutex_destroy(&e->ubs_mutex);
    }
}

static int frm_cb(int type, int qno, gm_ss_entity *entity)
{
    priv_avbs_t *pb;
    int ch_num, sub_num;

    for (ch_num = 0; ch_num < CAP_CH_NUM; ch_num++) {
        for (sub_num = 0; sub_num < RTSP_NUM_PER_CAP; sub_num++) {
            pb = &enc[ch_num].priv_bs[sub_num];

            if (pb->video.offs == (int)(entity->data) && pb->video.len == entity->size && pb->video.qno==qno) {
                pthread_mutex_lock(&pb->video.priv_vbs_mutex);
                pb->video.offs = 0;
                pb->video.len = 0;
                pthread_mutex_unlock(&pb->video.priv_vbs_mutex);
            }
        }
    }

    return 0;
}

priv_avbs_t *find_file_sr(char *name, int srno)
{
    int ch_num, sub_num, hit=0;
    priv_avbs_t *pb;

    for (ch_num = 0; ch_num < CAP_CH_NUM; ch_num++) {
        for (sub_num = 0; sub_num < RTSP_NUM_PER_CAP; sub_num++) {
            pb = &enc[ch_num].priv_bs[sub_num];

            if ((pb->sr == srno) && (pb->name) && (strcmp(pb->name, name) == 0)) {
                hit = 1;
                break;
            }
        }

        if (hit)
            break;
    }

    return (hit ? pb : NULL);
}

static int cmd_cb(char *name, int sno, int cmd, void *p)
{
    int ret = -1;
    priv_avbs_t *pb;

    switch(cmd) {
        case GM_STREAM_CMD_OPTION:
            ret = 0;
            break;

        case GM_STREAM_CMD_DESCRIBE:
            ret = 0;
            break;

        case GM_STREAM_CMD_OPEN:
            log_error("%s:%d <GM_STREAM_CMD_OPEN>", __FUNCTION__, __LINE__);
            ERR_GOTO(-10, cmd_cb_err);
            break;

        case GM_STREAM_CMD_SETUP:
            ret = 0;
            break;

        case GM_STREAM_CMD_PLAY:
            if ( strncmp(name, "live/", 5) == 0 ) {

                if ((pb = find_file_sr(name, sno)) == NULL)
                    ERR_GOTO(-1, cmd_cb_err);

                if (pb->video.qno >= 0)
                    pb->play = 1;
            }
            ret = 0;
            break;

        case GM_STREAM_CMD_PAUSE:
            log_info("%s:%d <GM_STREAM_CMD_PAUSE>", __FUNCTION__, __LINE__);
            ret = 0;
            break;

        case GM_STREAM_CMD_TEARDOWN:
            if ( strncmp(name, "live/", 5) == 0 ) {
                if ((pb = find_file_sr(name, sno)) == NULL)
                    ERR_GOTO(-1, cmd_cb_err);
                pb->play = 0;
            }
            ret = 0;
            break;

        default:
            log_error("%s: not support cmd %d", __func__, cmd);
            break;
    }

cmd_cb_err:
    if ( ret < 0 ) {
        log_error("%s: cmd %d error %d", __func__, cmd, ret);
    }
    return ret;
}

void *enqueue_thread(void *ptr)
{
    while (rtspd_sysinit) {
        if (rtspd_set_event)
            bs_new_event();

        if (set_poll_event() < 0) {
            sleep(1);
            continue;
        }
        usleep(1000);
    }
    env_release_resources();
    pthread_exit(NULL);

    return NULL;
}

void gm_update_bs_info(void)
{
    int cap_ch,cap_path,rec_track;
    int ch=0;
     avbs_t *avbs;
     gm_enc_t *param;

    for (cap_ch = 0; cap_ch < CAP_CH_NUM; cap_ch++) {
        for (cap_path = 0; cap_path < CAP_PATH_NUM; cap_path++) {
            param = &enc_param[cap_ch][cap_path];
            for (rec_track = 0; rec_track < ENC_TRACK_NUM; rec_track++) {
                if (param->bindfd[rec_track]) {
                    avbs = &enc[cap_ch].bs[ch];
                    avbs->video.enc_type = param->enc[rec_track].enc_type;
                    ch++;
                }
            }
        }
    }
}

int env_init(void)
{
    int ret = 0;
    int ch_num, sub_num;
    av_t *e;
    avbs_t *b;
    priv_avbs_t *pb;

    memset(enc,0,sizeof(enc));

    // * Initial private data
    for (ch_num = 0; ch_num < CAP_CH_NUM; ch_num++) {
        e = &enc[ch_num];

        if (pthread_mutex_init(&e->ubs_mutex, NULL)) {
            log_error("env_init: mutex init failed");
            exit(-1);
        }

        for (sub_num = 0; sub_num < RTSP_NUM_PER_CAP; sub_num++) {
            b                 = &e->bs[sub_num];
            b->opt_type       = RTSP_LIVE_STREAMING;
            b->video.enc_type = ENC_TYPE_H264;
            b->event          = NONE_BS_EVENT;
            b->enabled        = DVR_ENC_EBST_DISABLE;
            b->video.enabled  = DVR_ENC_EBST_DISABLE;

            pb                = &e->priv_bs[sub_num];
            pb->video.qno     = -1;
            pb->video.offs    = 0;
            pb->video.len     = 0;
            pb->sr            = -1;

            if (pthread_mutex_init(&pb->video.priv_vbs_mutex, NULL)) {
                log_error("env_enc_init: priv_vbs mutex init failed");
                exit(-1);
            }
        }
    }

    // * Update bs info from decoder
    gm_update_bs_info();

    srand((unsigned int)time(NULL));

    if ((ret = stream_server_init(ipptr, (int) sys_port, 0, 1444, 256, SR_MAX, VQ_MAX, VQ_LEN, AQ_MAX, AQ_LEN, frm_cb, cmd_cb)) < 0)
        log_error("stream_server_init, ret %d", ret);

    if ((ret = stream_server_start()) < 0)
        log_error("stream_server_start, ret %d", ret);

    return ret;
}

static unsigned chipid;
void gm_enc_init(int cap_ch, int cap_path, int rec_track, int enc_type, int mode, int framerate, int bitrate, int width, int height)
{
    gm_enc_t *param;
    DECLARE_ATTR(cap_attr, gm_cap_attr_t);
    DECLARE_ATTR(h264e_attr, gm_h264e_attr_t);
    DECLARE_ATTR(mpeg4e_attr, gm_mpeg4e_attr_t);
    DECLARE_ATTR(dnr_attr, gm_3dnr_attr_t);
    DECLARE_ATTR(mjpege_attr, gm_mjpege_attr_t);

    param = &enc_param[cap_ch][cap_path];

    if (param->cap.obj == NULL) {
        param->cap.obj = gm_new_obj(GM_CAP_OBJECT);            // * New capture object
        cap_attr.cap_vch = cap_ch;

        // * GM813x capture path 0(liveview), 1(substream), 2(substream), 3(mainstream)
        cap_attr.path = cap_path;
        cap_attr.enable_mv_data = 0;
        gm_set_attr(param->cap.obj, &cap_attr);                // * Set capture attribute

        // * Enable 3dnr if resolution > capture dim / 2
        if ((width >= (gm_system.cap[cap_ch].dim.width / 2)) &&
            (height >= (gm_system.cap[cap_ch].dim.height / 2))) {
            dnr_attr.enabled = 1;
            gm_set_attr(param->cap.obj, &dnr_attr);
        }

        memcpy(&param->cap.cap_attr, &cap_attr, sizeof(gm_cap_attr_t));
        memcpy(&param->cap.dnr_attr, &dnr_attr, sizeof(gm_3dnr_attr_t));
    }

    param->enc[rec_track].obj = gm_new_obj(GM_ENCODER_OBJECT); // * New encoder object
    param->enc[rec_track].enc_type = enc_type;

    switch (enc_type) {
        case ENC_TYPE_H264:
            h264e_attr.dim.width             = width;
            h264e_attr.dim.height            = height;
            h264e_attr.frame_info.framerate  = framerate;
            h264e_attr.ratectl.mode          = mode;
            h264e_attr.ratectl.gop           = 60;
            h264e_attr.ratectl.bitrate       = bitrate;
            h264e_attr.ratectl.bitrate_max   = bitrate;
            h264e_attr.b_frame_num           = 0;              // * B-frames per GOP (H.264 high profile)
            h264e_attr.enable_mv_data        = 0;              // * Disable H.264 motion data output
            h264e_attr.ratectl.init_quant    = 25;
            h264e_attr.ratectl.min_quant     = 20;
            h264e_attr.ratectl.max_quant     = 51;
            gm_set_attr(param->enc[rec_track].obj, &h264e_attr);
            memcpy(&param->enc[rec_track].codec.h264e_attr, &h264e_attr, sizeof(gm_h264e_attr_t));
            break;

        case ENC_TYPE_MPEG4:
            mpeg4e_attr.dim.width            = width;
            mpeg4e_attr.dim.height           = height;
            mpeg4e_attr.frame_info.framerate = framerate;
            mpeg4e_attr.ratectl.mode         = mode;
            mpeg4e_attr.ratectl.gop          = 60;
            mpeg4e_attr.ratectl.bitrate      = bitrate;
            mpeg4e_attr.ratectl.bitrate_max  = bitrate;
            gm_set_attr(param->enc[rec_track].obj, &mpeg4e_attr);
            memcpy(&param->enc[rec_track].codec.mpeg4e_attr, &mpeg4e_attr, sizeof(gm_mpeg4e_attr_t));
            break;

        case ENC_TYPE_MJPEG:
            mjpege_attr.dim.width            = width;
            mjpege_attr.dim.height           = height;
            mjpege_attr.frame_info.framerate = framerate;
            mjpege_attr.quality              = 30;
            gm_set_attr(param->enc[rec_track].obj, &mjpege_attr);
            memcpy(&param->enc[rec_track].codec.mjpege_attr, &mjpege_attr, sizeof(gm_mjpege_attr_t));
            break;

        default:
            log_error("Encoder type not supported: %s", rtsp_enc_type_str[enc_type]);
            break;
    }

    // * Bind channel recording
    param->bindfd[rec_track] = gm_bind(enc_groupfd, param->cap.obj, param->enc[rec_track].obj);

    // * Enable Scaler Encoder if downscaling is required (only for H264)
    if (enc_type == ENC_TYPE_H264 && (width < 1280 || height < 720)) {
        h264e_attr.ratectl.bitrate      = bitrate;
        h264e_attr.frame_info.framerate = framerate;
        h264e_attr.dim.width            = width;
        h264e_attr.dim.height           = height;
        gm_set_attr(sub_enc_object, &h264e_attr);
        sub_bindfd                      = gm_bind(enc_groupfd, param->cap.obj, sub_enc_object);
    }

    rtspd_avail_ch++;
}

int gm_get_chipinfo(void)
{
    FILE *fp;
    char buffer[256];
    int i;
    int chipid;
    char *match;

    fp = fopen("/proc/pmu/chipver","r");
    i = fread(buffer,1,sizeof(buffer),fp);
    fclose(fp);

    if (i == 0)
        return 0;

    buffer[i] = '\0';
    match = strstr(buffer, "81");

    if (match == NULL)
        return 0;

    sscanf(match,"%X",&chipid);

    return chipid;
}

static int gm_get_max_bandwidth(char *list)
{
    int bandwidth=0;
    int i;
    int ch;
    int tmp;
    char token[] = "\n \t";
    int sensor_res[] = {800,500,400,300,200,130,100,34,30,7};
    char *str;
    str = strtok(list,token);

    for (i=0;i<5;i++) {
        if (str == NULL)
            break;

        sscanf(str,"%02d",&ch);
        str += 3;
        sscanf(str,"%03d",&tmp);
        str = strtok(NULL,token);

        if (ch == 0 || tmp == 0)
             continue;

        tmp = tmp * sensor_res[i];
        tmp = tmp / ch;

        if (i <= 3) {
            bandwidth = 8*30;
            break;
        }

        if (bandwidth <= (tmp /100))
            bandwidth = tmp/100;
    }

    return bandwidth;
}

int gm_get_bandwidth_info(void)
{
    FILE *fp;
    char buffer[2048];
    int i;
    char *match;

    fp = fopen("/proc/videograph/vpd/spec_info","r");
    i = fread(buffer,1,sizeof(buffer),fp);
    fclose(fp);

    if (i == 0)
        buffer[i] = '\0';

    match = strstr(buffer,"[ENC CAPTURE]");

    if (match == NULL)
        return 0;

    match = strstr(match, "CH_0");

    if (match == NULL)
        return 0;

    match += 4;
    sscanf(match,"%X",&i);

    if (i == 0)
        return 0;

    if (gm_get_max_bandwidth((match+1)) > 62)
        return 1;
    else
        return 0;
}

void gm_graph_init(void)
{
    int cap_fps;
    int cap_h;
    int cap_w;
    int cap_resolution;
    int cap_bandwidth;

    gm_init();
    gm_get_sysinfo(&gm_system);

    if (cliArgs.framerate > 0)
        poll_wait_time = 1000000 / (cliArgs.framerate + 2);
    else
        poll_wait_time = 15000;

    cap_fps        = cliArgs.framerate;
    cap_h          = cliArgs.height;
    cap_w          = cliArgs.width;
    cap_bandwidth  = cap_fps * cap_h * cap_w;
    cap_resolution = cap_h * cap_w;

    memset(enc_param, 0, sizeof(enc_param));
    enc_groupfd = gm_new_groupfd();
    chipid = gm_get_chipinfo();
    chipid = (chipid >> 16) & 0x0000ffff;

    rtspd_avail_ch = 0;
    gm_enc_init(0, 0, 0, cliArgs.encoderType, cliArgs.bitrateMode, cliArgs.framerate, cliArgs.bitrate, cliArgs.width, cliArgs.height);
    gm_apply(enc_groupfd); // * Activate settings
}

void gm_graph_release(void)
{
    gm_enc_t *param;
    int cap_ch, cap_path, rec_track;

    for (cap_ch = 0; cap_ch < CAP_CH_NUM; cap_ch++) {
        for (cap_path = 0; cap_path < CAP_PATH_NUM; cap_path++) {
            param = &enc_param[cap_ch][cap_path];
            for (rec_track = 0; rec_track < ENC_TRACK_NUM; rec_track++) {
                if (param->bindfd[rec_track])
                    gm_unbind(param->bindfd[rec_track]);
            }
        }
    }

    gm_apply(enc_groupfd);

    for (cap_ch = 0; cap_ch < CAP_CH_NUM; cap_ch++) {
        for (cap_path = 0; cap_path < CAP_PATH_NUM; cap_path++) {
            param = &enc_param[cap_ch][cap_path];

            for (rec_track = 0; rec_track < ENC_TRACK_NUM; rec_track++) {
                if (param->enc[rec_track].obj)
                    gm_delete_obj(param->enc[rec_track].obj);
            }

            if (param->cap.obj)
                gm_delete_obj(param->cap.obj);
        }
    }

    gm_delete_groupfd(enc_groupfd);
    gm_release();
}

void *encode_thread(void *ptr)
{
    int i, j, ch = 0, ret, cap_ch, cap_path, rec_track, rcv_nr, w, h;
    int first_play[CAP_CH_NUM][RTSP_NUM_PER_CAP];
    priv_avbs_t *pb;
    avbs_t *avbs;
    gm_enc_multi_bitstream_t bs[CAP_CH_NUM][RTSP_NUM_PER_CAP];
    gm_pollfd_t poll_fds[CAP_CH_NUM][RTSP_NUM_PER_CAP];
    gm_enc_t *param;
    static struct timeval prev;
    struct timeval cur, tout;
    static int timeval_init = 0;
    int diff;

    memset(poll_fds, 0, sizeof(poll_fds));

    for (cap_ch = 0; cap_ch < CAP_CH_NUM; cap_ch++) {
        for (cap_path = 0; cap_path < CAP_PATH_NUM; cap_path++) {
            param = &enc_param[cap_ch][cap_path];
            for (rec_track = 0; rec_track < ENC_TRACK_NUM; rec_track++) {
                if (param->bindfd[rec_track]) {
                    poll_fds[cap_ch][ch].bindfd = param->bindfd[rec_track];
                    poll_fds[cap_ch][ch].event  = GM_POLL_READ;

                    avbs = &enc[cap_ch].bs[ch];
                    get_enc_res(&param->enc[rec_track], NULL, &w, &h);

                    pb = &enc[cap_ch].priv_bs[ch];
                    pb->video.bs_buf_len = w * h * 3 / 2;
                    pb->video.bs_buf     = malloc(pb->video.bs_buf_len);
                    pb->video.cap_ch     = cap_ch;
                    pb->video.cap_path   = cap_path;
                    pb->video.rec_track  = rec_track;
                    ch++;
                }
            }
        }
    }

    while(1) {
        if (rtspd_sysinit == 0)
            break;

        if (rtspd_set_event) {
            usleep(2000);
            continue;
        }

        if (set_poll_event() < 0) {
            usleep(2000);
            continue;
        }

        gettimeofday(&cur, NULL);

        if (timeval_init == 0) {
            timeval_init = 1;
            tout.tv_sec  = 0;
            tout.tv_usec = poll_wait_time;
        } else {
            diff         = (cur.tv_usec < prev.tv_usec) ? (cur.tv_usec+1000000-prev.tv_usec) : (cur.tv_usec-prev.tv_usec);
            tout.tv_usec = (diff > poll_wait_time) ? (tout.tv_usec = 0) : (poll_wait_time - diff);
        }

        usleep(tout.tv_usec);
        gettimeofday(&prev, NULL);
        ret = 0;

        if (rtspd_sysinit == 0)
            break;

        ret = gm_poll(&poll_fds[0][0], CAP_CH_NUM * RTSP_NUM_PER_CAP, 2000);

        if (ret == GM_TIMEOUT) {
            log_error("GM Poll timeout!!");
            continue;
        }

        rcv_nr = 0;
        memset(bs, 0, sizeof(bs));

        for (i = 0; i < CAP_CH_NUM; i++) {
            for (j = 0; j < RTSP_NUM_PER_CAP; j++) {
                pb = &enc[i].priv_bs[j];

                if (pb->video.offs || pb->video.len)
                    continue;

                if (poll_fds[i][j].revent.event != GM_POLL_READ)
                    continue;

                if (poll_fds[i][j].revent.bs_len > pb->video.bs_buf_len) {
                    log_error("%d_%d: bindfd(%p) bitstream buffer length is not enough! (%d_bytes vs %d_bytes)", i, j, poll_fds[i][j].bindfd, poll_fds[i][j].revent.bs_len, pb->video.bs_buf_len);
                    continue;
                }

                rcv_nr++;
                bs[i][j].bindfd = poll_fds[i][j].bindfd;

                // * Set buffer point
                bs[i][j].bs.bs_buf = pb->video.bs_buf;

                // * Set buffer length
                bs[i][j].bs.bs_buf_len = pb->video.bs_buf_len;

                // * Turn receiving MV data off
                bs[i][j].bs.mv_buf = 0;
                bs[i][j].bs.mv_buf_len = 0;

                if (pb->play == 0)
                    first_play[i][j] = -1;
            }
        }

        if (rcv_nr == 0)
            continue;

        if (rtspd_sysinit == 0)
            break;

        if ( (ret = gm_recv_multi_bitstreams(&bs[0][0], CAP_CH_NUM * RTSP_NUM_PER_CAP)) < 0 ) {
            // <= -1: fail, 0: success
            log_error("Failed to receive bitstream (gm_recv_multi_bitstreams).");
            continue;
        }

        for (i = 0; i < CAP_CH_NUM; i++) {
            for (j = 0; j < RTSP_NUM_PER_CAP; j++) {

                if (rtspd_sysinit == 0)
                    continue;

                pb = &enc[i].priv_bs[j];
                avbs = &enc[i].bs[j];

                if ((bs[i][j].retval < 0) && bs[i][j].bindfd)
                    log_error("Failed to receive bitstream.");

                else if (bs[i][j].retval == GM_SUCCESS) {

                    if (avbs->video.enc_type != ENC_TYPE_MJPEG) {
                        if ((pb->play == 1) && (bs[i][j].bs.keyframe == 1))
                            first_play[i][j] = 1;
                    }
                    else
                        first_play[i][j] = 1;

                    if (first_play[i][j] == 1) {
                        pthread_mutex_lock(&pb->video.priv_vbs_mutex);
                        pb->video.offs  = (int) (bs[i][j].bs.bs_buf);
                        pb->video.len   = bs[i][j].bs.bs_len;
                        pb->video.tv_ms = bs[i][j].bs.timestamp;
                        pthread_mutex_unlock(&pb->video.priv_vbs_mutex);

                        // * Write buffer to the rtsp service and empty buffers
                        if (write_rtp_frame_ext(i, j, (void *)pb->video.offs, pb->video.len, bs[i][j].bs.timestamp) == 1) {
                            pb->video.offs = (int)NULL;
                            pb->video.len  = 0;
                        }
                    }

                    print_enc_average(i, j, bs[i][j].bs.bs_len, &prev);
                }
            }
        }
    }

    pthread_exit(NULL);
    encode_thread_id = (pthread_t)NULL;
    return NULL;
}

void update_video_sdp(int cap_ch, int cap_path, int rec_track)
{
    char *bitstream_data = NULL;
    unsigned int bitstream_data_len;
    gm_enc_multi_bitstream_t bs;
    gm_pollfd_t poll_fds;
    int ret, cnt=0, w, h;
    gm_enc_t *param;
    priv_avbs_t *pb;

    memset(&poll_fds, 0, sizeof(poll_fds));
    param = &enc_param[cap_ch][cap_path];

    if (param->bindfd[rec_track]) {
        poll_fds.bindfd = param->bindfd[rec_track];
        poll_fds.event = GM_POLL_READ;
        get_enc_res(&param->enc[rec_track], NULL, &w, &h);
        pb = &enc[cap_ch].priv_bs[cap_path];
        bitstream_data_len = w * h * 3 / 2;
        bitstream_data = malloc(bitstream_data_len);
    }
    else return;

    while(1) {
        ret = gm_poll(&poll_fds, 1, 2000);
        if ( ret == GM_TIMEOUT ) {
            log_error("GM Poll timeout");
            continue;
        }

        memset(&bs, 0, sizeof(bs));

        if ( poll_fds.revent.event != GM_POLL_READ )
            continue;

        if ( poll_fds.revent.bs_len > bitstream_data_len) {
            log_error("bitstream buffer length is too small! %d, %d", poll_fds.revent.bs_len, bitstream_data_len);
            continue;
        }

        bs.bindfd = poll_fds.bindfd;

        // * Set buffer point
        bs.bs.bs_buf = bitstream_data;

        // * Set buffer length
        bs.bs.bs_buf_len = bitstream_data_len;

        // * Turn off receiving motion data
        bs.bs.mv_buf = 0;
        bs.bs.mv_buf_len = 0;

        ret = gm_recv_multi_bitstreams(&bs, 1);     // * -1: Fail 0: Success

        if ( ret < 0 )
            log_error("Failed to receive bitstream (gm_recv_multi_bitstreams).");
        else if ( (bs.retval < 0) && bs.bindfd )
            log_error("Failed to receive bitstream.");

        else if ( ret == 0 && bs.retval == GM_SUCCESS ) {
            if (bs.bs.keyframe == 1 ) {
                switch (cliArgs.encoderType) {
                    case 0:
                        stream_sdp_parameter_encoder("H264", (unsigned char *) bs.bs.bs_buf, bs.bs.bs_len, pb->video.sdpstr, SDPSTR_MAX);
                    case 1:
                        stream_sdp_parameter_encoder("H264", (unsigned char *) bs.bs.bs_buf, bs.bs.bs_len, pb->video.sdpstr, SDPSTR_MAX);
                    case 2:
                        stream_sdp_parameter_encoder("H264", (unsigned char *) bs.bs.bs_buf, bs.bs.bs_len, pb->video.sdpstr, SDPSTR_MAX);
                }
                break;
            }
            else {
                if (++cnt > 100) {
                    log_error("Timeout reached while waiting for keyframe");
                    break;
                }
            }
        }
    }
    if (bitstream_data)
        free(bitstream_data);
}

static int rtspd_start(int port)
{
    int ret, ch_num, stream;
    pthread_attr_t attr;

    if (rtspd_sysinit == 1)
        return -1;

    if ((0 < port) && (port < 0x10000))
        sys_port = port;

    if ((ret = env_init()) < 0)
        return ret;

    if (pthread_mutex_init(&stream_queue_mutex, NULL)) {
        log_error("rtspd_start: mutex init failed");
        exit(-1);
    }

    rtspd_sysinit = 1;

    // * Encode Thread
    if (encode_thread_id == (pthread_t)NULL) {
        pthread_attr_init(&attr);
        pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
        ret = pthread_create(&encode_thread_id, &attr, &encode_thread, NULL);
        pthread_attr_destroy(&attr);
    }

    // * Enqueue Thread
    if (enqueue_thread_id == (pthread_t)NULL) {
        pthread_attr_init(&attr);
        pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
        ret = pthread_create(&enqueue_thread_id, &attr, &enqueue_thread, NULL);
        pthread_attr_destroy(&attr);
    }

    for (ch_num = 0; ch_num < CAP_CH_NUM; ch_num++) {
        pthread_mutex_lock(&enc[ch_num].ubs_mutex);

        for (stream = 0; stream < RTSP_NUM_PER_CAP; stream++)
            env_set_bs_new_event(ch_num, stream, START_BS_EVENT);

        pthread_mutex_unlock(&enc[ch_num].ubs_mutex);
    }

    return 0;
}

static void rtspd_stop(void)
{
    pthread_mutex_destroy(&stream_queue_mutex);
    rtspd_sysinit = 0;
}

static void print_usage(void)
{
    printf("Usage:\n");
    printf(" ./rtspd [-bfwhmup] [-j|-4]\n");
    printf(
        "\nAvailable options:\n"
        "-b [1-8192]    - Set the bitrate         (default: 8192)\n"
        "-f [1-15]      - Set the framerate       (default: 15)\n"
        "-w [1-1280]    - Set the image width     (default: 1280 pixels)\n"
        "-h [1-720]     - Set the image height    (default: 720 pixels)\n"
        "-m [1-4]       - Set the bitrate mode    (default: 1, CBR)\n"
        "-u string      - Set the user name       (default: none)\n"
        "-p string      - Set the user password   (default: none)\n"
        "-j (optional)  - Use MJPEG encoding      (default: off)\n"
        "-4 (optional)  - Use MPEG4 encoding      (default: off)\n"
    );

	exit(EXIT_FAILURE);
}

void signal_handler(int sig)
{
    log_fatal("Exiting rtspd: CTRL+C pressed, or exit requested");

    rtspd_stop();
    gm_graph_release();
    closelog();

    exit(EXIT_SUCCESS);
}

int main(int argc, char *argv[])
{
    int i;
    int cap_ch, cap_path, rec_track;

    openlog("rtspd", LOG_PID, LOG_DAEMON);

    cliArgs.bitrate     = 8192;
    cliArgs.framerate   = 15;
    cliArgs.width       = 1280;
    cliArgs.height      = 720;
    cliArgs.bitrateMode = GM_EVBR;
    cliArgs.encoderType = ENC_TYPE_H264;
    cliArgs.user        = NULL;
    cliArgs.password    = NULL;

    if (argc > 1) {
        for (i = 1; i < argc; i++) {
            if (argv[i][0] != '-' ) {
                log_error("Invalid input: %s!", argv[i]);
                print_usage();
                return 1;
            } else {
                switch (argv[i][1]) {
                    case 'b':
                        cliArgs.bitrate     = atoi(&argv[i][2]);
                        break;
                    case 'f':
                        cliArgs.framerate   = atoi(&argv[i][2]);
                        break;
                    case 'w':
                        cliArgs.width       = atoi(&argv[i][2]);
                        break;
                    case 'h':
                        cliArgs.height      = atoi(&argv[i][2]);
                        break;
                    case 'm':
                        cliArgs.bitrateMode = atoi(&argv[i][2]);
                        break;
                    case 'j':
                        cliArgs.encoderType = ENC_TYPE_MJPEG;
                        break;
                    case '4':
                        cliArgs.encoderType = ENC_TYPE_MPEG4;
                        break;
                    case 'u':
                        cliArgs.user = &argv[i][2];
                        break;
                    case 'p':
                        cliArgs.password = &argv[i][2];
                        break;
                    default:
                        log_error("Unknown argument: %s", argv[i]);
                        print_usage();
                        return 1;
                }
            }
        }
    }

    if ((cliArgs.bitrate < 1) || (cliArgs.bitrate > 8192)) {
        log_error("Use a maximum bitrate of 8192 and a minimum of 1");
        return 1;
    }

    if ((cliArgs.framerate < 1) || (cliArgs.framerate > 30)) {
        log_error("A framerate below 1 or higher than 30 fps is not supported.");
        return 1;
    }

    if ((cliArgs.height < 1) || (cliArgs.height > 720)) {
        log_error("A height bigger than 720p or below 1 is not supported.");
        return 1;
    }

    if ((cliArgs.width < 1) || (cliArgs.width > 1280)) {
        log_error("A width wider than 720p is not supported.");
        return 1;
    }

    if ((cliArgs.bitrateMode < 1) || (cliArgs.bitrateMode > 4)) {
        log_error("Bitrate mode should be in between 1 and 4");
        return 1;
    }

    log_info("Starting the RTSP Daemon");

    if (cliArgs.user != NULL && strcmp(cliArgs.user, "") != 0 && cliArgs.password != NULL && strcmp(cliArgs.password, "") != 0) {
        rtsp_use_auth = 1;
        log_info("Enabling stream authentication.");
        log_info("Stream username: %s", cliArgs.user);
        log_info("Stream password: %s", cliArgs.password);
    }

    // * Initializing gmlib
    gm_graph_init();

    log_info("Width        : %d", cliArgs.width);
    log_info("Height       : %d", cliArgs.height);
    log_info("Encoder      : %s", cliArgs.encoderType == ENC_TYPE_H264 ? "H264" : cliArgs.encoderType == ENC_TYPE_MJPEG ? "MJPEG" : "MPEG4");
    log_info("Framerate    : %d", cliArgs.framerate);
    log_info("Bitrate      : %d", cliArgs.bitrate);
    log_info("Bitrate Mode : %d", cliArgs.bitrateMode);

    for (cap_ch = 0; cap_ch < CAP_CH_NUM; cap_ch++) {
        for (cap_path = 0; cap_path < CAP_PATH_NUM; cap_path++) {
            for (rec_track = 0; rec_track < ENC_TRACK_NUM; rec_track++) {
                update_video_sdp(cap_ch, cap_path, rec_track);
            }
        }
    }

    // * Use our handler for the signals so we can do some cleanup at quit
    signal(SIGINT,  signal_handler);
    signal(SIGHUP,  signal_handler);
    signal(SIGTERM, signal_handler);

    // * Start the rtsp threads
    rtspd_start(554);

    while(1) {
        usleep(10000);
    }

    return 0;
}
