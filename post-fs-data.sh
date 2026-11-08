#!/system/bin/sh
MODDIR=${0%/*}
# Early boot permissive hook for modified system components
setenforce 0

# Mount fixed vendor script before init starts class main services
if [ -f "$MODDIR/01_lh8n_sysfs.sh" ]; then
    mount --bind "$MODDIR/01_lh8n_sysfs.sh" /vendor/bin/01_lh8n_sysfs.sh 2>/dev/null || true
fi
