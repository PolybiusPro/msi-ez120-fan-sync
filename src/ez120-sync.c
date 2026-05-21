#include <errno.h>
#include <fcntl.h>
#include <glob.h>
#include <linux/hidraw.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#define VENDOR_ID  0x0db0
#define PRODUCT_ID  0x1f1e

static int send_feature_report(const char *devnode) {
    int fd = open(devnode, O_RDWR);
    if (fd < 0) {
        return -1;
    }

    unsigned char report[32] = {
        0x09, 0x01, 0x00, 0x62, 0xff
    };

    int rc = ioctl(fd, HIDIOCSFEATURE(sizeof(report)), report);
    if (rc < 0) {
        fprintf(stderr, "HIDIOCSFEATURE failed on %s: %s\n", devnode, strerror(errno));
        close(fd);
        return -1;
    }

    close(fd);
    return 0;
}

int main(void) {
    glob_t g;
    memset(&g, 0, sizeof(g));

    int grc = glob("/dev/hidraw*", 0, NULL, &g);
    if (grc != 0) {
        fprintf(stderr, "No hidraw devices found\n");
        return 1;
    }

    int found = 0;

    for (size_t i = 0; i < g.gl_pathc; i++) {
        const char *path = g.gl_pathv[i];
        int fd = open(path, O_RDWR);
        if (fd < 0) {
            continue;
        }

        struct hidraw_devinfo info;
        memset(&info, 0, sizeof(info));

        if (ioctl(fd, HIDIOCGRAWINFO, &info) < 0) {
            close(fd);
            continue;
        }

        if (info.vendor == VENDOR_ID && info.product == PRODUCT_ID) {
            close(fd);
            printf("Found target device: %s (%04x:%04x)\n", path, info.vendor, info.product);
            if (send_feature_report(path) == 0) {
                found = 1;
                break;
            }
        } else {
            close(fd);
        }
    }

    globfree(&g);

    if (!found) {
        fprintf(stderr, "Target HID device %04x:%04x not found or send failed\n", VENDOR_ID, PRODUCT_ID);
        return 1;
    }

    return 0;
}