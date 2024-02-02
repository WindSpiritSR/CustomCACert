#!/system/bin/sh

exec > /data/local/tmp/CustomCACert.log
exec 2>&1

set -x

MODDIR=${0%/*}

set_context() {
    [ "$(getenforce)" = "Enforcing" ] || return 0

    default_selinux_context=u:object_r:system_file:s0
    selinux_context=$(ls -Zd $1 | awk '{print $1}')

    if [ -n "$selinux_context" ] && [ "$selinux_context" != "?" ]; then
        chcon -R $selinux_context $2
    else
        chcon -R $default_selinux_context $2
    fi
}

chown -R 0:0 ${MODDIR}/system/etc/security/cacerts
set_context /system/etc/security/cacerts ${MODDIR}/system/etc/security/cacerts

# Android 14 support
# Since Magisk ignore /apex for module file injections, use non-Magisk way
if [ -d /apex/com.android.conscrypt/cacerts ]; then
    # Clone directory into tmpfs
    rm -f /data/local/tmp/sys-ca-copy
    mkdir -p /data/local/tmp/sys-ca-copy
    mount -t tmpfs tmpfs /data/local/tmp/sys-ca-copy
    cp -f /apex/com.android.conscrypt/cacerts/* /data/local/tmp/sys-ca-copy/

    # Do the same as in Magisk module
    cp -f ${MODDIR}/system/etc/security/cacerts/* /data/local/tmp/sys-ca-copy
    chown -R 0:0 /data/local/tmp/sys-ca-copy
    set_context /apex/com.android.conscrypt/cacerts /data/local/tmp/sys-ca-copy

    # Mount directory inside APEX if it is valid, and remove temporary one.
    CERTS_NUM="$(ls -1 /data/local/tmp/sys-ca-copy | wc -l)"
    if [ "$CERTS_NUM" -gt 10 ]; then
        mount --bind /data/local/tmp/sys-ca-copy /apex/com.android.conscrypt/cacerts
        for pid in 1 $(pgrep zygote) $(pgrep zygote64); do
            nsenter --mount=/proc/${pid}/ns/mnt -- \
                mount --bind /data/local/tmp/sys-ca-copy /apex/com.android.conscrypt/cacerts
        done
    else
        echo "Cancelling replacing CA storage due to safety"
    fi
    umount /data/local/tmp/sys-ca-copy
    rmdir /data/local/tmp/sys-ca-copy
fi
