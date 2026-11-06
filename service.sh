#!/system/bin/sh
MODDIR=${0%/*}

# Wait for boot completion
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

# Ensure sysfs node permissions are accessible
chmod 0666 /sys/class/leds/aw22xxx_led/* 2>/dev/null || true
chmod 0666 /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/* 2>/dev/null || true
chmod 0666 /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/leds/aw22xxx_led/* 2>/dev/null || true
chmod 0666 /sys/devices/platform/11d02000.i2c/i2c-2/2-006a/* 2>/dev/null || true
chmod 0666 /sys/led/led/tran_led_cmd 2>/dev/null || true

# Auto-grant notification listener if not already granted
cmd notification allow_listener com.transsion.lightbelt/com.transsion.lightbelt.service.LBBackgroundService 2>/dev/null || true

