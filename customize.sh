#!/system/bin/sh
SKIPUNZIP=0

ui_print "*****************************************"
ui_print "*      Tecno LH8n LightBelt Service     *"
ui_print "*   Native AW22xxx Backlight for HyperOS *"
ui_print "*****************************************"

ui_print "- Installing LightBelt system-less priv-app..."
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755

# Install APK directly into package manager for immediate availability
if [ -f "$MODPATH/system/priv-app/LightBelt/LightBelt.apk" ]; then
    ui_print "- Registering package in Android Package Manager..."
    pm install -r -d "$MODPATH/system/priv-app/LightBelt/LightBelt.apk" >/dev/null 2>&1 || true
fi

# Set hardware node permissions
ui_print "- Configuring AW22xxx sysfs permissions..."
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
echo 1 > /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/leds/aw22xxx_led/hwen 2>/dev/null || true

# Grant Notification Listener access
ui_print "- Enabling notification listener..."
cmd notification allow_listener com.transsion.lightbelt/com.transsion.lightbelt.service.LBBackgroundService 2>/dev/null || true

ui_print "*****************************************"
ui_print "* Installation complete! Reboot or enjoy *"
ui_print "*****************************************"

