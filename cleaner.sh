#!/bin/bash

# 检查是否以 root 用户运行
if [[ $EUID -ne 0 ]]; then
    echo "请使用 root 用户或通过 sudo 运行此脚本。"
    exit 1
fi

# 显示清理前磁盘空间使用情况
echo "开始系统清理操作..."
echo "清理前磁盘使用情况："
df -h | grep "^/dev"

# 记录清理前磁盘使用情况
before=$(df / | awk 'NR==2 {print $4}')

# 1. 清理 APT 缓存文件
echo "清理 APT 缓存文件..."
sudo apt-get autoclean -y > /dev/null
sudo apt-get clean -y > /dev/null
echo "APT 缓存清理完成！"

# 2. 清理系统日志文件
echo "清理系统日志文件..."
log_size=$(sudo du -sh /var/log 2>/dev/null | awk '{print $1}')
sudo journalctl --vacuum-time=7d > /dev/null
sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;
echo "日志文件清理完成！释放日志目录大小：$log_size"

# 3. 清理临时文件
echo "清理临时文件..."
temp_size=$(sudo du -sh /tmp 2>/dev/null | awk '{print $1}')
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
echo "临时文件清理完成！释放临时目录大小：$temp_size"

# 4. 清理用户缓存文件
echo "清理用户缓存..."
user_cache_size=$(du -sh ~/.cache 2>/dev/null | awk '{print $1}')
rm -rf ~/.cache/*
echo "用户缓存清理完成！释放用户缓存大小：$user_cache_size"

# 5. 清理浏览器缓存（可选）
echo "清理浏览器缓存（如果有 Firefox 和 Chrome）..."
firefox_cache_size=$(du -sh ~/.mozilla/firefox/*.default-release/cache2 2>/dev/null | awk '{print $1}')
chrome_cache_size=$(du -sh ~/.cache/google-chrome 2>/dev/null | awk '{print $1}')
rm -rf ~/.mozilla/firefox/*.default-release/cache2/*
rm -rf ~/.cache/google-chrome/*
echo "Firefox 缓存清理完成！释放大小：${firefox_cache_size:-0}"
echo "Chrome 缓存清理完成！释放大小：${chrome_cache_size:-0}"

# 显示清理后的磁盘空间使用情况
echo "清理完成，当前磁盘使用情况："
df -h | grep "^/dev"

# 记录清理后磁盘使用情况
after=$(df / | awk 'NR==2 {print $4}')

# 计算释放的总空间
released=$(echo "$before $after" | awk '{printf "%.2f", ($1 - $2)/1024}')

echo
echo "系统清理完成！"
echo "总共释放磁盘空间：${released} MB"