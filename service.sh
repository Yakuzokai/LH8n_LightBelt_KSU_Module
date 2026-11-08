#!/system/bin/sh
MODDIR=${0%/*}

# Wait for boot completion
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

# Ensure vendor script is mount-bound with our non-destructive thermal watchdog
if [ -f "$MODDIR/01_lh8n_sysfs.sh" ]; then
    if ! mount | grep -q "/vendor/bin/01_lh8n_sysfs.sh"; then
        mount --bind "$MODDIR/01_lh8n_sysfs.sh" /vendor/bin/01_lh8n_sysfs.sh 2>/dev/null || true
    fi
    # If 01_lh8n_sysfs daemon is not running, start it in background
    if ! ps -A | grep -q "01_lh8n_sysfs.sh"; then
        sh /vendor/bin/01_lh8n_sysfs.sh &
    fi
fi

# Ensure directory traversal permissions are always 0755
chmod 0755 /sys 2>/dev/null || true
chmod 0755 /sys/class 2>/dev/null || true
chmod 0755 /sys/class/leds 2>/dev/null || true
chmod 0755 /sys/devices 2>/dev/null || true
chmod 0755 /sys/devices/platform 2>/dev/null || true
chmod 0755 /sys/devices/platform/11d21000.i2c 2>/dev/null || true
chmod 0755 /sys/devices/platform/11d21000.i2c/i2c-2 2>/dev/null || true
chmod 0755 /sys/devices/platform/11d21000.i2c/i2c-2/2-006a 2>/dev/null || true
chmod 0755 /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/leds 2>/dev/null || true
chmod 0755 /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/leds/aw22xxx_led 2>/dev/null || true
chmod 0755 /sys/devices/platform/mtk_leds 2>/dev/null || true
chmod 0755 /sys/devices/platform/mtk_leds/leds 2>/dev/null || true
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

# Start LBBackgroundService to manage active LED states
am start-service com.transsion.lightbelt/com.transsion.lightbelt.service.LBBackgroundService 2>/dev/null || true
