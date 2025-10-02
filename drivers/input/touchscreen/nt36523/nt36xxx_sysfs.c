#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/sysfs.h>
#include <linux/kobject.h>
#include <linux/device.h>
#include <linux/input.h>
#include <linux/fs.h>
#include "nt36xxx.h"

static int switch_firmware = 0;

static ssize_t switch_firmware_show(struct kobject *kobj, struct kobj_attribute *attr, char *buf)
{
    return sprintf(buf, "%d\n", switch_firmware);
}

static ssize_t switch_firmware_store(struct kobject *kobj, struct kobj_attribute *attr,
                                      const char *buf, size_t count)
{
    int new_value;

    if (sscanf(buf, "%d", &new_value) != 1)
        return -EINVAL;

    if (new_value != switch_firmware) {
        switch_firmware = new_value;

        if (switch_firmware == 1) {
            ts->fw_name = "novatek_nt36523_k81a_fw01_new.bin";
        } else {
            ts->fw_name = "novatek_nt36523_k81_fw01.bin";
        }
    }

    return count;
}

static struct kobj_attribute switch_firmware_attribute = __ATTR(switch_firmware, 0664, switch_firmware_show, switch_firmware_store);

static struct kobject *nt36523_kobject;

static int __init nt36523_sysfs_init(void)
{
    int retval;

    nt36523_kobject = kobject_create_and_add("touchpanel", kernel_kobj);
    if (!nt36523_kobject)
        return -ENOMEM;

    retval = sysfs_create_file(nt36523_kobject, &switch_firmware_attribute.attr);
    if (retval) {
        kobject_put(nt36523_kobject);
        return retval;
    }

    return 0;
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
