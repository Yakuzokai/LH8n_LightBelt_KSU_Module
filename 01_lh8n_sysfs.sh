#!/system/bin/sh

# Ensure SELinux permissive
setenforce 0 2>/dev/null

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
chmod 0666 /sys/devices/platform/11d21000.i2c/i2c-2/2-006a/leds/aw22xxx_led/* 2>/dev/null

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

# Initialize LED controller in awake standby state with safe current level (35mA)
echo 9 > /sys/class/leds/aw22xxx_led/cfg 2>/dev/null
echo 1 > /sys/class/leds/aw22xxx_led/hwen 2>/dev/null
echo 8 > /sys/class/leds/aw22xxx_led/imax 2>/dev/null
echo 180 > /sys/class/leds/aw22xxx_led/brightness 2>/dev/null
echo "00 00 00 00 00 00" > /sys/led/led/tran_led_cmd 2>/dev/null
sleep 0.05
echo "00 01 00 00 00 00" > /sys/led/led/tran_led_cmd 2>/dev/null

# Ensure native helper never runs (prevents thermal watchdog from cutting hwen power)
killall -9 lh8n_helper 2>/dev/null

LAST_RR=""
LAST_SMART=""
LAST_PAPER=""
TICK_COUNT=0

# Blur Configuration: Permanent Gaussian blur, Advanced Textures toggle removed
settings put global disable_window_blurs 0
settings put secure background_blur_enable 1
settings put system background_blur_enable 1
setprop persist.sys.sf.disable_blurs false
setprop persist.sysui.disableBlur false
setprop persist.sys.background_blur_supported false
setprop persist.sys.background_blur_status_default true
setprop persist.sys.background_blur_setting 1
setprop persist.sys.background_blur_keyguard_disabled false

# Background thread: Auto-grant LightBelt notification listener & populate defaults
(
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 2
    done
    sleep 3
    cmd notification allow_listener com.transsion.lightbelt/com.transsion.lightbelt.service.LBBackgroundService 2>/dev/null
    
    [ -z "$(settings get global tran_led_lighting_settings 2>/dev/null)" ] && settings put global tran_led_lighting_settings 1
    [ -z "$(settings get global tran_led_notification_settings 2>/dev/null)" ] && settings put global tran_led_notification_settings 1
    [ -z "$(settings get global tran_led_charge_settings 2>/dev/null)" ] && settings put global tran_led_charge_settings 1
    [ -z "$(settings get global tran_led_low_power_settings 2>/dev/null)" ] && settings put global tran_led_low_power_settings 1
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
            settings put secure night_display_activated 1
        else
            settings put secure night_display_activated 0
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
                am broadcast -a miui.intent.action.ACTION_QUICK_CHARGE_TYPE --ei miui.intent.extra.quick_charge_type "$TYPE" --ei miui.intent.extra.POWER_MAX "$WATT"
                ;;
        esac
    fi

    # 4. Refresh rate synchronization
    TICK_COUNT=$((TICK_COUNT + 1))
    if [ "$TICK_COUNT" -ge 2 ]; then
        TICK_COUNT=0
        SMART=$(settings get system is_smart_fps 2>/dev/null)
        USER_RR=$(settings get secure user_refresh_rate 2>/dev/null)
        
        if [ "$SMART" = "1" ]; then
            if [ "$LAST_SMART" != "1" ]; then
                settings put system min_refresh_rate 60.0
                settings put system peak_refresh_rate 120.0
                LAST_SMART="1"
                LAST_RR="smart"
            fi
        else
            LAST_SMART="0"
            if [ "$USER_RR" != "$LAST_RR" ]; then
                case "$USER_RR" in
                    60)
                        settings put system min_refresh_rate 60.0
                        settings put system peak_refresh_rate 60.0
                        LAST_RR="60"
                        ;;
                    90)
                        settings put system min_refresh_rate 90.0
                        settings put system peak_refresh_rate 90.0
                        LAST_RR="90"
                        ;;
                    120)
                        settings put system min_refresh_rate 120.0
                        settings put system peak_refresh_rate 120.0
                        LAST_RR="120"
                        ;;
                esac
            fi
        fi
    fi

    sleep 2.0
done
