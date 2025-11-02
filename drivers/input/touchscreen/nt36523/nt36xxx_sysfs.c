#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/sysfs.h>
#include <linux/kobject.h>
#include <linux/device.h>
#include <linux/input.h>
#include <linux/fs.h>
#include "nt36xxx.h"

extern struct kobject *touchpanel_kobj;

static int game_mode = 0;

static ssize_t game_mode_show(struct kobject *kobj, struct kobj_attribute *attr, char *buf)
{
    return sprintf(buf, "%d\n", game_mode);
}

static ssize_t game_mode_store(struct kobject *kobj, struct kobj_attribute *attr,
                                      const char *buf, size_t count)
{
    int new_value;

    if (sscanf(buf, "%d", &new_value) != 1)
        return -EINVAL;

    if (new_value != game_mode) {
        game_mode = new_value;

        if (game_mode == 1) {
            ts->fw_name = "novatek_nt36523_k81a_fw01_new.bin";
        } else {
            ts->fw_name = "novatek_nt36523_k81_fw01.bin";
        }
    }

    return count;
}

static struct kobj_attribute game_mode_attribute = __ATTR(game_mode, 0664, game_mode_show, game_mode_store);

static struct kobject *nt36523_kobject;

static int __init nt36523_sysfs_init(void)
{
    if (!touchpanel_kobj)
        return -ENODEV;

    return sysfs_create_file(touchpanel_kobj, &game_mode_attribute.attr);
}

static void __exit nt36523_sysfs_exit(void)
{
    kobject_put(nt36523_kobject);
}

module_init(nt36523_sysfs_init);
module_exit(nt36523_sysfs_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("YangQi0408");
MODULE_DESCRIPTION("A sysfs interface for switching the nt36523 touchscreen firmware.");
