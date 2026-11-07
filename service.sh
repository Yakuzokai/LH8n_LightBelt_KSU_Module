#!/system/bin/sh
MODDIR=${0%/*}

# Wait for boot completion
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

# Ensure directory traversal permissions are always 0755
chmod 0755 /sys/class/leds 2>/dev/null || true
chmod 0755 /sys/devices/platform/11d21000.i2c/i2c-2/2-006a 2>/dev/null || true
chmod 0755 /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/leds 2>/dev/null || true
chmod 0755 /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/leds/aw22xxx_led 2>/dev/null || true
chmod 0755 /sys/devices/platform/mtk_leds/leds/lcd-backlight 2>/dev/null || true

# Ensure file nodes are accessible to system user
find /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/leds/aw22xxx_led/ -type f -exec chmod 0666 {} + 2>/dev/null || true
chmod 0666 /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/tran_led_cmd 2>/dev/null || true
chmod 0666 /sys/led/led/tran_led_cmd 2>/dev/null || true
chmod 0666 /sys/devices/platform/mtk_leds/leds/lcd-backlight/brightness 2>/dev/null || true
chmod 0666 /sys/class/leds/lcd-backlight/brightness 2>/dev/null || true
chown -R system:system /sys/devices/platform/11d21000.i2c/i2c-2/2-006a 2>/dev/null || true

# Auto-grant notification listener if not already granted
cmd notification allow_listener com.transsion.lightbelt/com.transsion.lightbelt.service.LBBackgroundService 2>/dev/null || true

# Initialize AW22xxx hardware registers and output drivers
echo 1 > /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/leds/aw22xxx_led/hwen 2>/dev/null || true
echo 180 > /sys/class/leds/aw22xxx_led/brightness
echo "00 00 00 00 00 00" > /sys/led/led/tran_led_cmd
sleep 0.05
echo "00 01 00 00 00 00" > /sys/led/led/tran_led_cmd

