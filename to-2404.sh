#!/bin/bash
set -e
LOG="/tmp/upgrade-2404.log"
echo "开始一键升级到 Ubuntu 24.04 ($(date))" | tee $LOG

apt update -y && apt upgrade -y && apt dist-upgrade -y && apt autoremove -y >>$LOG 2>&1
apt install -y update-manager-core efibootmgr >>$LOG 2>&1

# 自动挂载 EFI（解决 Unsupported platform 问题）
mkdir -p /boot/efi
if ! mountpoint -q /boot/efi; then
    EFI=$(blkid -t TYPE=vfat -o device | head -1)
    [ -n "$EFI" ] && mount "$EFI" /boot/efi >>$LOG 2>&1
fi

# 移除常见冲突包
apt remove -y --purge zfs* nvidia* broadcom* 2>/dev/null || true

# 强制打开升级通道 + focal 自动跳 jammy
sed -i 's/Prompt=.*/Prompt=normal/' /etc/update-manager/release-upgrades
grep -q focal /etc/os-release && sed -i 's/focal/jammy/g' /etc/apt/sources.list && apt update >>$LOG 2>&1

echo "开始正式升级，日志见 $LOG" | tee -a $LOG
DEBIAN_FRONTEND=noninteractive \
do-release-upgrade -d -f DistUpgradeViewNonInteractive --allow-third-party >>$LOG 2>&1

echo "升级完成，系统即将重启" | tee -a $LOG
reboot
