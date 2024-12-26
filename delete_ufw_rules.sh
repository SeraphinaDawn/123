#!/bin/bash
# 一键删除 ufw 规则命令

# 检查是否以 root 用户运行
if [[ $EUID -ne 0 ]]; then
   echo "请使用 root 用户或通过 sudo 运行此脚本。"
   exit 1
fi

# 检测 ufw 是否安装
if ! command -v ufw &> /dev/null; then
    echo "未检测到 ufw 防火墙，正在自动安装 ufw..."

    # 根据不同的包管理器安装 ufw
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install ufw -y
    elif command -v yum &> /dev/null; then
        sudo yum install epel-release -y
        sudo yum install ufw -y
    else
        echo "无法自动安装 ufw，请手动安装后重试。"
        exit 1
    fi

    echo "ufw 已成功安装！"
fi

# 显示当前 ufw 规则
echo "当前的 UFW 规则："
sudo ufw status numbered

# 提示用户输入需要删除的规则编号
echo
read -p "请输入要删除的规则编号（用空格分隔，例如：1 3 5）： " rule_numbers

# 删除用户选择的规则
echo
for rule in $rule_numbers; do
    if sudo ufw status numbered | grep -q "\[$rule\]"; then
        echo "正在删除规则编号 [$rule]..."
        sudo ufw delete $rule
        # 重新显示规则，避免编号变化带来的问题
        sudo ufw status numbered
    else
        echo "规则编号 [$rule] 不存在，跳过..."
    fi
done

echo
echo "所有选择的规则已删除。"
sudo ufw status numbered

# 提示用户如何启用 ufw
echo
echo "完成！如果您尚未启用 ufw 防火墙，请按照以下步骤操作："
echo "1. 开放 SSH 默认端口（22）："
echo "   sudo ufw allow ssh"
echo "   如果更改过 SSH 端口，请使用以下命令放行新端口："
echo "   sudo ufw allow <你更改的端口>"
echo "2. 启用 ufw 防火墙："
echo "   sudo ufw enable"
echo

# 添加别名到 bashrc
if ! grep -q "alias ufw=" ~/.bashrc; then
  script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  echo "alias ufw='bash $script_dir/delete_ufw_rules.sh'" >> ~/.bashrc
  echo "快捷别名 'ufw' 已添加！请重新加载 shell 或输入 source ~/.bashrc"
fi

# 等待用户按任意键退出
echo
read -n 1 -s -r -p "按任意键退出脚本..."
echo
