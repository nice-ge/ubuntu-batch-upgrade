#!/bin/bash
LOG="/tmp/upgrade-step1.log"
echo "=== Step 1: 改源 + 打补丁 ($(date)) ===" | tee $LOG

# 兼容 Oracle Cloud arm64 ports + 清华源加速（避免卡死）
cat > /etc/apt/sources.list <<EOF
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ jammy main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ jammy-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ jammy-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ jammy-security main restricted universe multiverse
EOF

# 更新源 + 打补丁（加超时重试）
apt update -o Acquire::Retries=3 -y >>$LOG 2>&1
apt upgrade -y >>$LOG 2>&1
apt dist-upgrade -y >>$LOG 2>&1
apt autoremove -y >>$LOG 2>&1

apt install -y update-manager-core >>$LOG 2>&1

sed -i 's/Prompt=.*/Prompt=normal/' /etc/update-manager/release-upgrades

echo "Step 1 完成！源已切换 jammy，检查日志: $LOG" | tee -a $LOG
echo "运行 Step 2 开始真正升级: curl -fsSL https://raw.githubusercontent.com/nice-ge/ubuntu-batch-upgrade/main/step2.sh | sudo bash"
