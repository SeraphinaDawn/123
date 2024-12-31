#!/bin/bash

# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # 无颜色

# 检查是否以 root 用户运行
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}请使用 root 用户或通过 sudo 运行此脚本。${NC}"
    exit 1
fi

# 安装必要工具
install_ufw() {
    if ! command -v ufw &> /dev/null; then
        echo -e "${YELLOW}未检测到 ufw 防火墙，正在安装...${NC}"
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install ufw -y
        elif command -v yum &> /dev/null; then
            sudo yum install epel-release -y
            sudo yum install ufw -y
        elif command -v dnf &> /dev/null; then
            sudo dnf install ufw -y
        else
            echo -e "${RED}无法安装 ufw，请手动安装后重试。${NC}"
            exit 1
        fi
        echo -e "${GREEN}ufw 安装完成！${NC}"
    else
        echo -e "${BLUE}ufw 已安装，无需重复安装。${NC}"
    fi
}

# 创建 allow 脚本
create_allow_script() {
    cat << 'EOF' > /usr/local/bin/allow
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

if [[ -z $1 ]]; then
    echo "请指定需要放行的端口号，例如：allow 443"
    exit 1
fi

port_number=$1
if sudo ufw status | grep -q "\b$port_number\b"; then
    echo "端口 [$port_number] 已放行，无需重复操作。"
else
    echo "正在放行端口 [$port_number]..."
    sudo ufw allow "$port_number"
    echo "端口 [$port_number] 已成功放行！"
fi
EOF
    chmod +x /usr/local/bin/allow
    echo -e "${GREEN}allow 脚本已安装到 /usr/local/bin 并可直接使用！${NC}"
}

# 创建 cleaner 脚本
create_cleaner_script() {
    cat << 'EOF' > /usr/local/bin/clea
#!/bin/bash
# 检查是否以 root 用户运行
if [[ $EUID -ne 0 ]]; then
    echo "请使用 root 用户或通过 sudo 运行此脚本。"
    exit 1
fi

echo "开始系统清理操作..."
df -h | grep "^/dev"

if command -v apt-get &> /dev/null; then
    echo "清理 APT 缓存..."
    sudo apt-get autoclean -y > /dev/null
    sudo apt-get clean -y > /dev/null
elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
    echo "清理 YUM/DNF 缓存..."
    sudo yum clean all > /dev/null 2>&1 || sudo dnf clean all > /dev/null 2>&1
else
    echo "未检测到支持的包管理器，跳过缓存清理。"
fi

echo "清理系统日志..."
sudo journalctl --vacuum-time=7d > /dev/null
sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;

echo "清理完成！"
EOF
    chmod +x /usr/local/bin/clea
    echo -e "${GREEN}clea 脚本已安装到 /usr/local/bin 并可直接使用！${NC}"
}

# 创建 delete_ufw_rules 脚本
create_delete_ufw_script() {
    cat << 'EOF' > /usr/local/bin/ufw
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

read -p "请输入要删除的端口号（例如：80）： " port_number

if sudo ufw status numbered | grep -q "\b$port_number\b"; then
    echo "检测到端口 [$port_number] 的规则，正在删除..."
    while sudo ufw status numbered | grep -q "\b$port_number\b"; do
        rule_number=$(sudo ufw status numbered | grep "\b$port_number\b" | awk -F'[][]' '{print $2}' | head -n 1)
        sudo ufw delete "$rule_number"
    done
    echo "所有与端口 [$port_number] 相关的规则已删除！"
else
    echo "未检测到与端口 [$port_number] 相关的规则，无需删除。"
fi
EOF
    chmod +x /usr/local/bin/ufw
    echo -e "${GREEN}ufw 脚本已安装到 /usr/local/bin 并可直接使用！${NC}"
}

# 显示使用说明
show_usage() {
    echo
    echo -e "${BLUE}========================== 使用提示 ==========================${NC}"
    echo -e "${GREEN}UFW 防火墙配置完成！以下命令已安装并可直接使用：${NC}"
    echo -e "${YELLOW}1. 放行端口：${NC} ${CYAN}allow 443${NC}"
    echo -e "${YELLOW}2. 系统清理：${NC} ${CYAN}clea${NC}"
    echo -e "${YELLOW}3. 删除防火墙规则：${NC} ${CYAN}ufw${NC}"
    echo -e "${BLUE}=============================================================${NC}"
}

# 主安装流程
main() {
    echo -e "${BLUE}正在安装和配置必要内容...${NC}"
    install_ufw
    create_allow_script
    create_cleaner_script
    create_delete_ufw_script

    echo -e "${GREEN}所有脚本已成功安装到 /usr/local/bin 并全局可用！${NC}"
    show_usage
}

main
