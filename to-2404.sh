#!/bin/bash
set -e
echo "开始强制升级到 Ubuntu 24.04（Oracle Cloud arm64 专用）"

# 杀锁 + 修复残留
sudo killall -9 apt apt-get dpkg ucf 2>/dev/null || true
sudo rm -f /var/lib/dpkg/lock* /var/cache/apt/archives/lock*
sudo dpkg --configure -a || true
sudo apt --fix-broken install -y || true

# 用 Oracle 官方最快源（别换！）
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
sudo sed -i 's/focal/jammy/g' /etc/apt/sources.list
sudo apt update

# 打满补丁 + 删干净 oracle 内核
sudo apt upgrade -y && sudo apt dist-upgrade -y
sudo apt remove --purge $(dpkg -l | grep oracle | awk '{print $2}') -y || true
sudo apt autoremove -y

# 强制 normal 模式 + 直接升
sudo sed -i 's/Prompt=.*/Prompt=normal/' /etc/update-manager/release-upgrades
sudo DEBIAN_FRONTEND=noninteractive UCF_FORCE_CONFFNEW=1 \
     do-release-upgrade -f DistUpgradeViewNonInteractive --allow-third-party

echo "升级完成，准备重启..."
sudo reboot
