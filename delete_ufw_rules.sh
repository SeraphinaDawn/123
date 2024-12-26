#!/bin/bash
# 一键删除ufw规则命令
# 检查是否以 root 用户运行
if [[ $EUID -ne 0 ]]; then
   echo "请使用 root 用户或通过 sudo 运行此脚本。"
   exit 1
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
    echo "正在删除规则编号 [$rule]..."
    sudo ufw delete $rule
    # 重新显示规则，避免编号变化带来的问题
    sudo ufw status numbered
done

echo
echo "所有选择的规则已删除。"
sudo ufw status numbered

# 等待用户按任意键退出
echo
read -n 1 -s -r -p "按任意键退出脚本..."
echo



# 添加别名到 bashrc
if ! grep -q "alias ufw=" ~/.bashrc; then
  echo "alias ufw='bash $(pwd)/delete_ufw_rules.sh'" >> ~/.bashrc
  echo "快捷别名 'ufw' 已添加！请重新加载 shell 或输入 source ~/.bashrc"
fi
