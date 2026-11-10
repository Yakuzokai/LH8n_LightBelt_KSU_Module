#!/system/bin/sh

# Ensure SELinux permissive
setenforce 0 2>/dev/null

# Ensure directory traversal permissions are always 0755
for d in \
    /sys /sys/class /sys/class/leds /sys/devices /sys/devices/platform \
    /sys/devices/platform/11d21000.i2c /sys/devices/platform/11d21000.i2c/i2c-2 \
    /sys/devices/platform/11d21000.i2c/i2c-2/2-006a \
    /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/leds \
    /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/leds/aw22xxx_led \
    /sys/devices/platform/mtk_leds /sys/devices/platform/mtk_leds/leds \
    /sys/devices/platform/mtk_leds/leds/lcd-backlight; do
    chmod 0755 "$d" 2>/dev/null
done

find /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/ -type d -exec chmod 0755 {} + 2>/dev/null
find /sys/devices/platform/mtk_leds/ -type d -exec chmod 0755 {} + 2>/dev/null
find /sys/class/leds/ -type d -exec chmod 0755 {} + 2>/dev/null

# Set sysfs permissions and SELinux contexts
chmod 0666 /sys/devices/platform/charger/bypass_charger 2>/dev/null
chmod 0666 /sys/devices/platform/charger/tran_aichg_disable_charger 2>/dev/null
chmod 0666 /sys/led/led/tran_led_cmd 2>/dev/null
chmod 0666 /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/tran_led_cmd 2>/dev/null
chmod 0666 /sys/class/leds/aw22xxx_led/brightness 2>/dev/null
chmod 0666 /sys/class/leds/aw22xxx_led/effect 2>/dev/null
chmod 0666 /sys/class/leds/aw22xxx_led/cfg 2>/dev/null
chmod 0666 /sys/class/leds/aw22xxx_led/hwen 2>/dev/null
chmod 0666 /sys/class/leds/aw22xxx_led/imax 2>/dev/null
chmod 0666 /sys/class/leds/lcd-backlight/brightness 2>/dev/null
chmod 0666 /sys/devices/platform/mtk_leds/leds/lcd-backlight/brightness 2>/dev/null
find /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/leds/aw22xxx_led/ -type f -exec chmod 0666 {} + 2>/dev/null

# Safety guard: lock aw22xxx_led/rgb to root:system 0640 to prevent out-of-bounds UBSAN kernel panics
for node in /sys/class/leds/aw22xxx_led/rgb /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/leds/aw22xxx_led/rgb; do
    if [ -e "$node" ]; then
        chown root:system "$node" 2>/dev/null
        chmod 0640 "$node" 2>/dev/null
    fi
done

chcon u:object_r:sysfs:s0 /sys/devices/platform/charger/bypass_charger 2>/dev/null
chcon u:object_r:sysfs:s0 /sys/devices/platform/charger/tran_aichg_disable_charger 2>/dev/null
chcon u:object_r:sysfs:s0 /sys/led/led/tran_led_cmd 2>/dev/null
chcon u:object_r:sysfs:s0 /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/tran_led_cmd 2>/dev/null
chcon u:object_r:sysfs:s0 /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/leds/aw22xxx_led/* 2>/dev/null

CMD_FILE="/data/local/tmp/lh8n_cmd"
rm -f "$CMD_FILE"
touch "$CMD_FILE"
chmod 0666 "$CMD_FILE"
chcon u:object_r:shell_data_file:s0 "$CMD_FILE"

# Resolve startup command from cache or settings
STARTUP_CMD=""
[ -f "/data/local/tmp/lh8n_startup_cmd" ] && IFS= read -r STARTUP_CMD < /data/local/tmp/lh8n_startup_cmd 2>/dev/null

if [ -z "$STARTUP_CMD" ] || [ "$STARTUP_CMD" = "null" ]; then
    STARTUP_CMD=$(settings get global tran_led_startup_cmd 2>/dev/null)
fi

if [ -z "$STARTUP_CMD" ] || [ "$STARTUP_CMD" = "null" ]; then
    STARTUP_VAL=$(settings get global tran_led_startup_settings 2>/dev/null)
    case "$STARTUP_VAL" in
        0) STARTUP_CMD="00 03 01 00 00 00" ;; # 0: Dreamy Illusion
        1) STARTUP_CMD="00 31 02 00 00 00" ;; # 1: Racing / Speed
        2) STARTUP_CMD="00 04 00 00 00 00" ;; # 2: Soft Wave
        3) STARTUP_CMD="00 20 02 00 00 00" ;; # 3: Breathing Pulse
        4) STARTUP_CMD="00 20 03 00 00 00" ;; # 4: Party Rhythm
        5) STARTUP_CMD="00 01 00 00 00 00" ;; # 5: None / Disabled
        *) STARTUP_CMD="00 04 00 00 00 00" ;; # Default Soft Wave for LH8n
    esac
fi

MASTER_VAL=""
[ -f "/data/local/tmp/lh8n_master" ] && IFS= read -r MASTER_VAL < /data/local/tmp/lh8n_master 2>/dev/null
[ -z "$MASTER_VAL" ] && MASTER_VAL=$(settings get global tran_led_lighting_settings 2>/dev/null)
if [ "$MASTER_VAL" = "0" ]; then
    STARTUP_CMD="00 01 00 00 00 00"
fi

STARTUP_BRIGHTNESS=""
[ -f "/data/local/tmp/lh8n_startup_brightness" ] && IFS= read -r STARTUP_BRIGHTNESS < /data/local/tmp/lh8n_startup_brightness 2>/dev/null
[ -z "$STARTUP_BRIGHTNESS" ] && STARTUP_BRIGHTNESS=$(settings get global tran_led_startup_brightness 2>/dev/null)
[ -z "$STARTUP_BRIGHTNESS" ] && STARTUP_BRIGHTNESS=70

STARTUP_IMAX=""
[ -f "/data/local/tmp/lh8n_startup_imax" ] && IFS= read -r STARTUP_IMAX < /data/local/tmp/lh8n_startup_imax 2>/dev/null
[ -z "$STARTUP_IMAX" ] && STARTUP_IMAX=$(settings get global tran_led_startup_imax 2>/dev/null)

if [ -z "$STARTUP_IMAX" ] || [ "$STARTUP_IMAX" = "null" ]; then
    if [ "$STARTUP_BRIGHTNESS" -le 0 ] 2>/dev/null; then
        STARTUP_IMAX=0
        STARTUP_CMD="00 01 00 00 00 00"
    else
        STARTUP_IMAX=$(( ((STARTUP_BRIGHTNESS - 1) * 8 + 49) / 99 ))
        [ "$STARTUP_IMAX" -lt 0 ] && STARTUP_IMAX=0
        [ "$STARTUP_IMAX" -gt 8 ] && STARTUP_IMAX=8
    fi
fi
if [ "$STARTUP_BRIGHTNESS" -le 0 ] 2>/dev/null; then
    STARTUP_CMD="00 01 00 00 00 00"
fi

# Initialize LED controller in awake standby state with configured current level
echo 9 > /sys/class/leds/aw22xxx_led/cfg 2>/dev/null
echo 1 > /sys/class/leds/aw22xxx_led/hwen 2>/dev/null
echo "$STARTUP_IMAX" > /sys/class/leds/aw22xxx_led/imax 2>/dev/null
echo 180 > /sys/class/leds/aw22xxx_led/brightness 2>/dev/null
echo "00 00 00 00 00 00" > /sys/led/led/tran_led_cmd 2>/dev/null
sleep 0.05

# Trigger startup backlight effect while device is booting
if [ -n "$STARTUP_CMD" ] && [ "$STARTUP_CMD" != "00 01 00 00 00 00" ]; then
    echo "$STARTUP_CMD" > /sys/led/led/tran_led_cmd 2>/dev/null
else
    echo "00 01 00 00 00 00" > /sys/led/led/tran_led_cmd 2>/dev/null
fi

# Ensure native helper never runs (prevents thermal watchdog from cutting hwen power)
killall -9 lh8n_helper 2>/dev/null

LAST_RR=""
LAST_SMART=""
LAST_PAPER=""
TICK_COUNT=0

# Blur properties (Settings keys are applied post-boot by SysfsSettingsObserver once SettingsProvider is ready)
setprop persist.sys.sf.disable_blurs false
setprop persist.sysui.disableBlur false
setprop persist.sys.background_blur_supported false
setprop persist.sys.background_blur_status_default true
setprop persist.sys.background_blur_setting 1
setprop persist.sys.background_blur_keyguard_disabled false

# Background thread: Handle boot completion, listener grant, and settings sync
(
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 1
    done

    # Keep startup backlight visible for at least 4 seconds post-boot
    sleep 4

    CHG_STATUS=""
    CHG_ONLINE=""
    [ -r /sys/class/power_supply/battery/status ] && IFS= read -r CHG_STATUS < /sys/class/power_supply/battery/status 2>/dev/null
    [ -r /sys/class/power_supply/charger/online ] && IFS= read -r CHG_ONLINE < /sys/class/power_supply/charger/online 2>/dev/null

    if [ "$CHG_ONLINE" = "1" ] || [ "$CHG_STATUS" = "Charging" ] || [ "$CHG_STATUS" = "Full" ]; then
        CHG_CMD=$(settings get global tran_led_charge_effect_cmd 2>/dev/null)
        [ -z "$CHG_CMD" ] && [ -r /data/local/tmp/lh8n_charge_cmd ] && IFS= read -r CHG_CMD < /data/local/tmp/lh8n_charge_cmd 2>/dev/null
        [ -z "$CHG_CMD" ] && CHG_CMD="00 02 01 00 00 00"

        CHG_BRIGHT=$(settings get global tran_led_charge_brightness 2>/dev/null)
        [ -z "$CHG_BRIGHT" ] && [ -r /data/local/tmp/lh8n_charge_brightness ] && IFS= read -r CHG_BRIGHT < /data/local/tmp/lh8n_charge_brightness 2>/dev/null
        [ -z "$CHG_BRIGHT" ] && CHG_BRIGHT=70
        if [ "$CHG_BRIGHT" -le 0 ] 2>/dev/null; then
            echo "00 01 00 00 00 00" > /sys/led/led/tran_led_cmd 2>/dev/null
        else
            CHG_IMAX=$(( ((CHG_BRIGHT - 1) * 8 + 49) / 99 ))
            [ "$CHG_IMAX" -lt 0 ] && CHG_IMAX=0
            [ "$CHG_IMAX" -gt 8 ] && CHG_IMAX=8
            echo "$CHG_IMAX" > /sys/class/leds/aw22xxx_led/imax 2>/dev/null
            echo "$CHG_CMD" > /sys/led/led/tran_led_cmd 2>/dev/null
        fi
    else
        echo "00 01 00 00 00 00" > /sys/led/led/tran_led_cmd 2>/dev/null
    fi

    # Auto-grant notification listener for LBBackgroundService
    cmd notification allow_listener com.transsion.lightbelt/com.transsion.lightbelt.service.LBBackgroundService 2>/dev/null

    # Start LBBackgroundService to manage charging, notifications, battery alerts
    am start-service com.transsion.lightbelt/com.transsion.lightbelt.service.LBBackgroundService 2>/dev/null

    # Populate defaults if unset
    [ -z "$(settings get global tran_led_lighting_settings 2>/dev/null)" ] && settings put global tran_led_lighting_settings 1
    [ -z "$(settings get global tran_led_notification_settings 2>/dev/null)" ] && settings put global tran_led_notification_settings 1
    [ -z "$(settings get global tran_led_charge_settings 2>/dev/null)" ] && settings put global tran_led_charge_settings 1
    [ -z "$(settings get global tran_led_low_power_settings 2>/dev/null)" ] && settings put global tran_led_low_power_settings 1
    [ -z "$(settings get global tran_led_startup_settings 2>/dev/null)" ] && settings put global tran_led_startup_settings 3
    [ -z "$(settings get global tran_led_charge_brightness 2>/dev/null)" ] && settings put global tran_led_charge_brightness 70
    [ -z "$(settings get global tran_led_fully_charged_brightness 2>/dev/null)" ] && settings put global tran_led_fully_charged_brightness 70
    [ -z "$(settings get global tran_led_low_power_brightness 2>/dev/null)" ] && settings put global tran_led_low_power_brightness 70
    [ -z "$(settings get global tran_led_startup_brightness 2>/dev/null)" ] && settings put global tran_led_startup_brightness 70
    [ -z "$(settings get global tran_led_notification_brightness 2>/dev/null)" ] && settings put global tran_led_notification_brightness 70
    [ -z "$(settings get global tran_led_call_brightness 2>/dev/null)" ] && settings put global tran_led_call_brightness 70
    [ -z "$(settings get global tran_led_music_brightness 2>/dev/null)" ] && settings put global tran_led_music_brightness 70
    [ -z "$(settings get global tran_led_test_brightness 2>/dev/null)" ] && settings put global tran_led_test_brightness 70

    # Update cache files so next cold boot has immediate access
    S_CMD=$(settings get global tran_led_startup_cmd 2>/dev/null)
    if [ -n "$S_CMD" ] && [ "$S_CMD" != "null" ]; then
        echo "$S_CMD" > /data/local/tmp/lh8n_startup_cmd
    else
        S_VAL=$(settings get global tran_led_startup_settings 2>/dev/null)
        case "$S_VAL" in
            0) echo "00 03 01 00 00 00" > /data/local/tmp/lh8n_startup_cmd ;;
            1) echo "00 31 02 00 00 00" > /data/local/tmp/lh8n_startup_cmd ;;
            2) echo "00 04 00 00 00 00" > /data/local/tmp/lh8n_startup_cmd ;;
            3) echo "00 20 02 00 00 00" > /data/local/tmp/lh8n_startup_cmd ;;
            4) echo "00 20 03 00 00 00" > /data/local/tmp/lh8n_startup_cmd ;;
            5) echo "00 01 00 00 00 00" > /data/local/tmp/lh8n_startup_cmd ;;
        esac
    fi
    chmod 0666 /data/local/tmp/lh8n_startup_cmd 2>/dev/null

    IMAX_SET=$(settings get global tran_led_imax 2>/dev/null)
    [ -n "$IMAX_SET" ] && echo "$IMAX_SET" > /data/local/tmp/lh8n_imax && chmod 0666 /data/local/tmp/lh8n_imax 2>/dev/null

    M_SET=$(settings get global tran_led_lighting_settings 2>/dev/null)
    [ -n "$M_SET" ] && echo "$M_SET" > /data/local/tmp/lh8n_master && chmod 0666 /data/local/tmp/lh8n_master 2>/dev/null
) &

# Runtime monitoring, Settings sync, thermal watchdog & cmd handling are performed by
# SysfsSettingsObserver (lh8n_observer.dex) under u:r:ksu:s0 with zero init AVC spam.
# Hold silently so Android init never respawns this non-oneshot service.
while true; do
    sleep 3600
done

