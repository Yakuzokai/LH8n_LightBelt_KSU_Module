#!/system/bin/sh
# KernelSU Next action script: Test LED Lightstrip
echo "=== Testing Tecno LH8n Backlight LEDs ==="
echo 1 > /sys/class/leds/aw22xxx_led/hwen
echo 8 > /sys/class/leds/aw22xxx_led/imax
echo 255 > /sys/class/leds/aw22xxx_led/brightness
echo 4 > /sys/class/leds/aw22xxx_led/effect
echo 4 > /sys/class/leds/aw22xxx_led/cfg

sleep 3

echo '00 01 00 00 00 00' > /sys/led/led/tran_led_cmd

echo "=== Backlight Test Completed Successfully! ==="

