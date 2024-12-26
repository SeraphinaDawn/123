#!/bin/bash

# 检查是否以 root 用户运行
if [[ $EUID -ne 0 ]]; then
    echo "请使用 root 用户或通过 sudo 运行此脚本。"
    exit 1
fi

# 安装必要工具
install_ufw() {
    if ! command -v ufw &> /dev/null; then
        echo "未检测到 ufw 防火墙，正在安装..."
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install ufw -y
        elif command -v yum &> /dev/null; then
            sudo yum install epel-release -y
            sudo yum install ufw -y
        elif command -v dnf &> /dev/null; then
            sudo dnf install ufw -y
        else
            echo "无法安装 ufw，请手动安装后重试。"
            exit 1
        fi
        echo "ufw 安装完成！"
    else
        echo "ufw 已安装，无需重复安装。"
    fi
}

# 配置别名到 .bashrc
add_alias() {
    local name=$1
    local command=$2
    if ! grep -q "alias $name=" ~/.bashrc; then
        echo "alias $name='$command'" >> ~/.bashrc
        echo "别名 '$name' 已添加！"
    fi
}

# 创建 cleaner.sh 脚本
create_cleaner() {
    cat << 'EOF' > cleaner.sh
#!/bin/bash
# 检查是否以 root 用户运行
if [[ $EUID -ne 0 ]]; then
    echo "请使用 root 用户或通过 sudo 运行此脚本。"
    exit 1
fi

echo "开始系统清理操作..."
df -h | grep "^/dev"
before=$(df / | awk 'NR==2 {print $4}')

echo "清理 APT 缓存..."
sudo apt-get autoclean -y > /dev/null
sudo apt-get clean -y > /dev/null

echo "清理系统日志..."
log_size=$(sudo du -sh /var/log 2>/dev/null | awk '{print $1}')
sudo journalctl --vacuum-time=7d > /dev/null
sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;

echo "清理临时文件..."
temp_size=$(sudo du -sh /tmp 2>/dev/null | awk '{print $1}')
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

echo "清理用户缓存..."
user_cache_size=$(du -sh ~/.cache 2>/dev/null | awk '{print $1}')
rm -rf ~/.cache/*

echo "清理完成！"
df -h | grep "^/dev"
EOF
    chmod +x cleaner.sh
    echo "cleaner.sh 脚本创建完成！"
}

# 创建 delete_ufw_rules.sh 脚本
create_delete_ufw_rules() {
    cat << 'EOF' > delete_ufw_rules.sh
#!/bin/bash
# 检查是否以 root 用户运行
if [[ $EUID -ne 0 ]]; then
    echo "请使用 root 用户或通过 sudo 运行此脚本。"
    exit 1
fi

if ! command -v ufw &> /dev/null; then
    echo "未检测到 ufw 防火墙，请先安装后再运行此脚本。"
    exit 1
fi

echo "当前的 UFW 规则："
sudo ufw status numbered

read -p "请输入要删除的规则编号（用空格分隔，例如：1 3 5）： " rule_numbers
for rule in $rule_numbers; do
    if sudo ufw status numbered | grep -q "\[$rule\]"; then
        echo "正在删除规则编号 [$rule]..."
        sudo ufw delete $rule
    else
        echo "规则编号 [$rule] 不存在，跳过..."
    fi
done

echo "所有选择的规则已删除。"

echo "启用 ufw 防火墙时请记得开放 SSH 端口！"
echo "例如："
echo "  sudo ufw allow ssh"
echo "  sudo ufw enable"
EOF
    chmod +x delete_ufw_rules.sh
    echo "delete_ufw_rules.sh 脚本创建完成！"
}

# 显示 UFW 配置使用说明
show_ufw_usage() {
    echo
    echo "========================== 使用提示 =========================="
    echo "UFW 防火墙配置完成！如果尚未启用，请按照以下步骤操作："
    echo
    echo "1. 默认允许 SSH 端口（22）："
    echo "   sudo ufw allow ssh"
    echo
    echo "2. 如果更改过 SSH 端口，请放行新的端口（例如 2222）："
    echo "   sudo ufw allow <你更改的端口>"
    echo
    echo "3. 启用 UFW 防火墙："
    echo "   sudo ufw enable"
    echo
    echo "============================================================="
    echo
}

# 主安装流程
main() {
    echo "正在安装和配置必要内容..."
    install_ufw
    create_cleaner
    create_delete_ufw_rules

    echo "配置别名..."
    script_dir=$(pwd)
    add_alias clea "bash $script_dir/cleaner.sh"
    add_alias ufw "bash $script_dir/delete_ufw_rules.sh"

    echo "所有操作完成！请运行以下命令使别名生效："
    echo "source ~/.bashrc"

    # 显示 UFW 使用提示
    show_ufw_usage
}

main
