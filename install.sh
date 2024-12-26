#!/bin/bash

# 检查是否以 root 用户运行
if [[ $EUID -ne 0 ]]; then
    echo "请使用 root 用户或通过 sudo 运行此脚本。"
    exit 1
fi

# 下载脚本
echo "正在下载脚本..."
curl -L https://raw.githubusercontent.com/SeraphinaDawn/123/main/cleaner.sh -o cleaner.sh
curl -L https://raw.githubusercontent.com/SeraphinaDawn/123/main/delete_ufw_rules.sh -o delete_ufw_rules.sh
chmod +x cleaner.sh delete_ufw_rules.sh
echo "脚本下载完成！"

# 动态路径
script_dir=$(pwd)

# 添加别名
echo "正在配置别名..."
if ! grep -q "alias clea=" ~/.bashrc; then
  echo "alias clea='bash $script_dir/cleaner.sh'" >> ~/.bashrc
  echo "别名 'clea' 已添加！"
fi

if ! grep -q "alias ufw=" ~/.bashrc; then
  echo "alias ufw='bash $script_dir/delete_ufw_rules.sh'" >> ~/.bashrc
  echo "别名 'ufw' 已添加！"
fi

echo "所有操作完成！请运行以下命令使别名生效："
echo "source ~/.bashrc"
