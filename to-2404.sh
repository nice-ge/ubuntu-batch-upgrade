#!/bin/bash
set -e
LOG="/tmp/upgrade-2404.log"
echo "=== 开始 Oracle Cloud 专用升级到 24.04 ($(date)) ===" | tee $LOG

# 1. 先用清华源兜底，彻底避免卡死
cat > /etc/apt/sources.list <<EOF
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ jammy main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ jammy-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ jammy-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ jammy-security main restricted universe multiverse
EOF

apt update --allow-releaseinfo-change -y >>$LOG 2>&1 || apt update -y >>$LOG 2>&1
apt upgrade -y >>$LOG 2>&1
apt dist-upgrade -y >>$LOG 2>&1
apt autoremove -y >>$LOG 2>&1

apt install -y update-manager-core efibootmgr >>$LOG 2>&1

# 2. EFI 自动挂载
mkdir -p /boot/efi
if ! mountpoint -q /boot/efi; then
    EFI=$(blkid -t TYPE=vfat -o device | head -1)
    [ -n "$EFI" ] && mount "$EFI" /boot/efi >>$LOG 2>&1
fi

# 3. 清理冲突包 + 打开升级通道
apt remove -y --purge zfs* nvidia* broadcom* 2>/dev/null || true
sed -i 's/Prompt=.*/Prompt=normal/' /etc/update-manager/release-upgrades

echo "=== 源已切换清华源，开始正式升级（不会卡死）===" | tee -a $LOG

# 4. 加 10 秒延迟 + 重试机制，彻底解决卡死
sleep 10
DEBIAN_FRONTEND=noninteractive \
do-release-upgrade -d -f DistUpgradeViewNonInteractive --allow-third-party >>$LOG 2>&1 || \
(sleep 30 && do-release-upgrade -d -f DistUpgradeViewNonInteractive --allow-third-party >>$LOG 2>&1)

echo "升级已启动，系统即将重启" | tee -a $LOG
reboot
