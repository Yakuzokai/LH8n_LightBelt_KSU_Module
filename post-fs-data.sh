#!/system/bin/sh
MODDIR=${0%/*}

# Mount vendor script before init starts class main services if not already mounted
if [ -f "$MODDIR/01_lh8n_sysfs.sh" ] && [ -f /vendor/bin/01_lh8n_sysfs.sh ]; then
    chown 0:2000 "$MODDIR/01_lh8n_sysfs.sh" 2>/dev/null
    chmod 0755 "$MODDIR/01_lh8n_sysfs.sh" 2>/dev/null
    chcon u:object_r:vendor_file:s0 "$MODDIR/01_lh8n_sysfs.sh" 2>/dev/null
    if ! mount | grep -q "/vendor/bin/01_lh8n_sysfs.sh"; then
        mount --bind "$MODDIR/01_lh8n_sysfs.sh" /vendor/bin/01_lh8n_sysfs.sh 2>/dev/null || true
    fi
fi
