#!/bin/bash
LOG="/tmp/upgrade-step2.log"
echo "=== Step 2: 开始真正升级到 24.04 ($(date)) ===" | tee $LOG

# EFI 挂载 + 清理冲突
mkdir -p /boot/efi
if ! mountpoint -q /boot/efi; then
    EFI=$(blkid -t TYPE=vfat -o device | head -1)
    [ -n "$EFI" ] && mount "$EFI" /boot/efi >>$LOG 2>&1
fi

apt remove -y --purge zfs* nvidia* broadcom* 2>/dev/null || true

# 启动升级（无人值守 + 重试）
sleep 5  # 小延迟防卡
DEBIAN_FRONTEND=noninteractive \
do-release-upgrade -d -f DistUpgradeViewNonInteractive --allow-third-party >>$LOG 2>&1 || \
(sleep 30 && DEBIAN_FRONTEND=noninteractive do-release-upgrade -d -f DistUpgradeViewNonInteractive --allow-third-party >>$LOG 2>&1)

echo "升级启动成功！系统即将重启，日志: $LOG" | tee -a $LOG
reboot
