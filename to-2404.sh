#!/bin/bash
set -e
LOG="/tmp/upgrade-2404.log"
echo "=== 开始强制升级到 Ubuntu 24.04 ($(date)) ===" | tee $LOG

# 强制把所有 focal 替换成 jammy（兼容 ports 和普通源）
sed -i 's/focal/jammy/g' /etc/apt/sources.list
sed -i 's/focal/jammy/g' /etc/apt/sources.list.d/*.list 2>/dev/null || true

apt update -y >>$LOG 2>&1
apt upgrade -y >>$LOG 2>&1
apt dist-upgrade -y >>$LOG 2>&1
apt autoremove -y >>$LOG 2>&1

apt install -y update-manager-core efibootmgr >>$LOG 2>&1

# EFI 自动挂载
mkdir -p /boot/efi
if ! mountpoint -q /boot/efi; then
    EFI=$(blkid -t TYPE=vfat -o device | head -1)
    [ -n "$EFI" ] && mount "$EFI" /boot/efi >>$LOG 2>&1
fi

# 移除常见冲突包
apt remove -y --purge zfs* nvidia* broadcom* 2>/dev/null || true

# 强制升级通道
sed -i 's/Prompt=.*/Prompt=normal/' /etc/update-manager/release-upgrades

echo "=== 源已强制切换到 jammy，开始真正升级 ===" | tee -a $LOG
DEBIAN_FRONTEND=noninteractive \
do-release-upgrade -d -f DistUpgradeViewNonInteractive --allow-third-party >>$LOG 2>&1

echo "升级结束，系统即将重启" | tee -a $LOG
reboot
