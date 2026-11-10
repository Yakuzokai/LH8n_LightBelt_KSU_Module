#!/system/bin/sh

# Ensure SELinux permissive
setenforce 0 2>/dev/null

# Ensure directory traversal permissions are always 0755
chmod 0755 /sys 2>/dev/null
chmod 0755 /sys/class 2>/dev/null
chmod 0755 /sys/class/leds 2>/dev/null
chmod 0755 /sys/devices 2>/dev/null
chmod 0755 /sys/devices/platform 2>/dev/null
chmod 0755 /sys/devices/platform/11d21000.i2c 2>/dev/null
chmod 0755 /sys/devices/platform/11d21000.i2c/i2c-2 2>/dev/null
chmod 0755 /sys/devices/platform/11d21000.i2c/i2c-2/2-006a 2>/dev/null
chmod 0755 /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/leds 2>/dev/null
chmod 0755 /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/leds/aw22xxx_led 2>/dev/null
chmod 0755 /sys/devices/platform/mtk_leds 2>/dev/null
chmod 0755 /sys/devices/platform/mtk_leds/leds 2>/dev/null
chmod 0755 /sys/devices/platform/mtk_leds/leds/lcd-backlight 2>/dev/null

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
[ -f "/data/local/tmp/lh8n_startup_cmd" ] && STARTUP_CMD=$(cat /data/local/tmp/lh8n_startup_cmd 2>/dev/null)

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
[ -f "/data/local/tmp/lh8n_master" ] && MASTER_VAL=$(cat /data/local/tmp/lh8n_master 2>/dev/null)
[ -z "$MASTER_VAL" ] && MASTER_VAL=$(settings get global tran_led_lighting_settings 2>/dev/null)
if [ "$MASTER_VAL" = "0" ]; then
    STARTUP_CMD="00 01 00 00 00 00"
fi

STARTUP_BRIGHTNESS=""
[ -f "/data/local/tmp/lh8n_startup_brightness" ] && STARTUP_BRIGHTNESS=$(cat /data/local/tmp/lh8n_startup_brightness 2>/dev/null)
[ -z "$STARTUP_BRIGHTNESS" ] && STARTUP_BRIGHTNESS=$(settings get global tran_led_startup_brightness 2>/dev/null)
[ -z "$STARTUP_BRIGHTNESS" ] && STARTUP_BRIGHTNESS=70

STARTUP_IMAX=""
[ -f "/data/local/tmp/lh8n_startup_imax" ] && STARTUP_IMAX=$(cat /data/local/tmp/lh8n_startup_imax 2>/dev/null)
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

# Trigger startup backlight effect while device is booting!
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

# Blur Configuration: Permanent Gaussian blur, Advanced Textures toggle removed
settings put global disable_window_blurs 0 2>/dev/null || true
settings put secure background_blur_enable 1 2>/dev/null || true
settings put system background_blur_enable 1 2>/dev/null || true
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

    # Determine whether plugged into charger
    CHG_STATUS=$(cat /sys/class/power_supply/battery/status 2>/dev/null)
    CHG_ONLINE=$(cat /sys/class/power_supply/charger/online 2>/dev/null)

    if [ "$CHG_ONLINE" = "1" ] || [ "$CHG_STATUS" = "Charging" ] || [ "$CHG_STATUS" = "Full" ]; then
        CHG_CMD=$(settings get global tran_led_charge_effect_cmd 2>/dev/null)
        [ -z "$CHG_CMD" ] && CHG_CMD=$(cat /data/local/tmp/lh8n_charge_cmd 2>/dev/null)
        [ -z "$CHG_CMD" ] && CHG_CMD="00 02 01 00 00 00"

        CHG_BRIGHT=$(settings get global tran_led_charge_brightness 2>/dev/null)
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
        # Turn off startup effect once boot completes and user reaches lockscreen
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

# Background daemon loop
while true; do
    # 1. Thermal Safety Watchdog (Real hardware emergency cutoff at 70°C; do NOT pull hwen low)
    SOC_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
    if [ "$SOC_TEMP" -ge 70000 ]; then
        echo "00 01 00 00 00 00" > /sys/led/led/tran_led_cmd 2>/dev/null
        echo 9 > /sys/class/leds/aw22xxx_led/cfg 2>/dev/null
    fi

    # 2. Reading Mode synchronization
    PAPER=$(settings get system screen_paper_mode_enabled 2>/dev/null)
    [ -z "$PAPER" ] && PAPER="0"

    if [ "$PAPER" != "$LAST_PAPER" ]; then
        LAST_PAPER="$PAPER"
        if [ "$PAPER" = "1" ]; then
            settings put secure night_display_activated 1 2>/dev/null || true
        else
            settings put secure night_display_activated 0 2>/dev/null || true
        fi
    fi

    # 3. Command file handle
    if [ -s "$CMD_FILE" ]; then
        CMD=$(cat "$CMD_FILE")
        > "$CMD_FILE"
        case "$CMD" in
            *BYPASS*1*)
                echo 1 > /sys/devices/platform/charger/bypass_charge
                echo 1 > /sys/devices/platform/charger/tran_aichg_disable_charge
                ;;
            *BYPASS*0*)
                echo 0 > /sys/devices/platform/charger/bypass_charge
                echo 0 > /sys/devices/platform/charger/tran_aichg_disable_charge
                ;;
            *LED*0*)
                echo 9 > /sys/class/leds/aw22xxx_led/cfg
                echo 0 > /sys/class/leds/aw22xxx_led/effect
                echo 0 > /sys/led/led/tran_led_cmd 2>/dev/null
                ;;
            *LED*1*)
                echo 13 > /sys/class/leds/aw22xxx_led/cfg
                echo 7 > /sys/class/leds/aw22xxx_led/effect
                echo 1 > /sys/led/led/tran_led_cmd 2>/dev/null
                ;;
            *LED*2*)
                echo 4 > /sys/class/leds/aw22xxx_led/cfg
                echo 4 > /sys/class/leds/aw22xxx_led/effect
                echo 2 > /sys/led/led/tran_led_cmd 2>/dev/null
                ;;
            *LED*3*)
                echo 1 > /sys/class/leds/aw22xxx_led/cfg
                echo 1 > /sys/class/leds/aw22xxx_led/effect
                echo 3 > /sys/led/led/tran_led_cmd 2>/dev/null
                ;;
            *LED*4*)
                echo 0 > /sys/class/leds/aw22xxx_led/cfg
                echo 1 > /sys/class/leds/aw22xxx_led/effect
                echo 4 > /sys/led/led/tran_led_cmd 2>/dev/null
                ;;
            *QC_TYPE*)
                TYPE=$(echo "$CMD" | awk '{print $2}')
                WATT=$(echo "$CMD" | awk '{print $3}')
                am broadcast -a miui.intent.action.ACTION_QUICK_CHARGE_TYPE --ei miui.intent.extra.quick_charge_type "$TYPE" --ei miui.intent.extra.POWER_MAX "$WATT" 2>/dev/null || true
                ;;
        esac
    fi

    # 4. Refresh rate synchronization and periodic sysfs permission watchdog
    TICK_COUNT=$((TICK_COUNT + 1))
    if [ "$((TICK_COUNT % 5))" -eq 0 ]; then
        chmod 0755 /sys/class/leds 2>/dev/null
        chmod 0755 /sys/devices/platform/11d21000.i2c/i2c-2/2-006a 2>/dev/null
        chmod 0755 /sys/devices/platform/mtk_leds/leds/lcd-backlight 2>/dev/null
        chmod 0666 /sys/class/leds/lcd-backlight/brightness 2>/dev/null
        chmod 0666 /sys/devices/platform/mtk_leds/leds/lcd-backlight/brightness 2>/dev/null
        chmod 0666 /sys/led/led/tran_led_cmd 2>/dev/null
        chmod 0666 /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/tran_led_cmd 2>/dev/null

        # Sync startup and power settings to cache files for next cold boot
        S_CMD=$(settings get global tran_led_startup_cmd 2>/dev/null)
        if [ -n "$S_CMD" ] && [ "$S_CMD" != "null" ]; then
            echo "$S_CMD" > /data/local/tmp/lh8n_startup_cmd
        else
            S_CUR=$(settings get global tran_led_startup_settings 2>/dev/null)
            case "$S_CUR" in
                0) echo "00 03 01 00 00 00" > /data/local/tmp/lh8n_startup_cmd ;;
                1) echo "00 31 02 00 00 00" > /data/local/tmp/lh8n_startup_cmd ;;
                2) echo "00 04 00 00 00 00" > /data/local/tmp/lh8n_startup_cmd ;;
                3) echo "00 20 02 00 00 00" > /data/local/tmp/lh8n_startup_cmd ;;
                4) echo "00 20 03 00 00 00" > /data/local/tmp/lh8n_startup_cmd ;;
                5) echo "00 01 00 00 00 00" > /data/local/tmp/lh8n_startup_cmd ;;
            esac
        fi
        chmod 0666 /data/local/tmp/lh8n_startup_cmd 2>/dev/null

        IMAX_CUR=$(settings get global tran_led_imax 2>/dev/null)
        [ -n "$IMAX_CUR" ] && echo "$IMAX_CUR" > /data/local/tmp/lh8n_imax && chmod 0666 /data/local/tmp/lh8n_imax 2>/dev/null

        M_CUR=$(settings get global tran_led_lighting_settings 2>/dev/null)
        [ -n "$M_CUR" ] && echo "$M_CUR" > /data/local/tmp/lh8n_master && chmod 0666 /data/local/tmp/lh8n_master 2>/dev/null
    fi

    if [ "$TICK_COUNT" -ge 2 ]; then
        TICK_COUNT=0
        SMART=$(settings get system is_smart_fps 2>/dev/null)
        USER_RR=$(settings get secure user_refresh_rate 2>/dev/null)
        
        if [ "$SMART" = "1" ]; then
            if [ "$LAST_SMART" != "1" ]; then
                settings put system min_refresh_rate 60.0 2>/dev/null || true
                settings put system peak_refresh_rate 120.0 2>/dev/null || true
                LAST_SMART="1"
                LAST_RR="smart"
            fi
        else
            LAST_SMART="0"
            if [ "$USER_RR" != "$LAST_RR" ]; then
                case "$USER_RR" in
                    60)
                        settings put system min_refresh_rate 60.0 2>/dev/null || true
                        settings put system peak_refresh_rate 60.0 2>/dev/null || true
                        LAST_RR="60"
                        ;;
                    90)
                        settings put system min_refresh_rate 90.0 2>/dev/null || true
                        settings put system peak_refresh_rate 90.0 2>/dev/null || true
                        LAST_RR="90"
                        ;;
                    120)
                        settings put system min_refresh_rate 120.0 2>/dev/null || true
                        settings put system peak_refresh_rate 120.0 2>/dev/null || true
                        LAST_RR="120"
                        ;;
                esac
            fi
        fi
    fi

    sleep 2.0
done
