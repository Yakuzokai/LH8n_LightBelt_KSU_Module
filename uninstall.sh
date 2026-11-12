#!/system/bin/sh
# Turn off backlight cleanly
echo "00 01 00 00 00 00" > /sys/led/led/tran_led_cmd 2>/dev/null || true

# Clean up cached startup & brightness parameters
rm -f /data/local/tmp/lh8n_* 2>/dev/null || true

