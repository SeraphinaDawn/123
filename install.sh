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

# 配置别名到 .bashrc
add_alias() {
    local name=$1
    local command=$2
    if ! grep -q "alias $name=" ~/.bashrc; then
        echo "alias $name='$command'" >> ~/.bashrc
        echo -e "${GREEN}别名 '$name' 已添加！${NC}"
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
    chmod +x cleaner.sh
    echo -e "${GREEN}cleaner.sh 脚本创建完成！${NC}"
}

# 创建 allow_ufw_port.sh 脚本
create_allow_ufw_port() {
    cat << 'EOF' > allow_ufw_port.sh
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
    chmod +x allow_ufw_port.sh
    echo -e "${GREEN}allow_ufw_port.sh 脚本创建完成！${NC}"
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
    chmod +x delete_ufw_rules.sh
    echo -e "${GREEN}delete_ufw_rules.sh 脚本创建完成！${NC}"
}

# 显示 UFW 配置使用说明
show_ufw_usage() {
    echo
    echo -e "${BLUE}========================== 使用提示 ==========================${NC}"
    echo -e "${GREEN}以下别名已配置并可使用：${NC}"
    echo -e "${YELLOW}1. 放行端口：${NC} ${CYAN}allow 443${NC} ${GREEN}（运行 bash allow_ufw_port.sh 放行指定端口）${NC}"
    echo -e "${YELLOW}2. 系统清理：${NC} ${CYAN}clea${NC} ${GREEN}（运行 bash cleaner.sh 进行清理）${NC}"
    echo -e "${YELLOW}3. 删除规则：${NC} ${CYAN}ufw${NC} ${GREEN}（运行 bash delete_ufw_rules.sh 删除规则）${NC}"
    echo -e "${GREEN}请运行以下命令使别名生效：${NC} ${CYAN}source ~/.bashrc${NC}"
    echo -e "${BLUE}=============================================================${NC}"
    echo
    echo -e "${BLUE}========================== CentOS 注意 ==========================${NC}"
    echo -e "${GREEN}如果使用 CentOS，请按照以下步骤操作：${NC}"
    echo -e "${YELLOW}1. 禁用 firewalld 防火墙：${NC}"
    echo -e "${CYAN}   sudo systemctl stop firewalld${NC}"
    echo -e "${CYAN}   sudo systemctl disable firewalld${NC}"
    echo -e "${YELLOW}2. 启用 UFW 防火墙：${NC}"
    echo -e "${CYAN}   sudo systemctl enable ufw${NC}"
    echo -e "${CYAN}   sudo systemctl start ufw${NC}"
    echo -e "${GREEN}所有操作完成！请运行以下命令使别名生效：${NC} ${CYAN}source ~/.bashrc${NC}"" 
    echo -e "${BLUE}=============================================================${NC}"
}

# 主安装流程
main() {
    echo -e "${BLUE}正在安装和配置必要内容...${NC}"
    install_ufw
    create_cleaner
    create_allow_ufw_port
    create_delete_ufw_rules

    script_dir=$(pwd)
    add_alias clea "bash $script_dir/cleaner.sh"
    add_alias allow "bash $script_dir/allow_ufw_port.sh"
    add_alias ufw "bash $script_dir/delete_ufw_rules.sh"

    echo -e "${GREEN}所有操作完成！${NC}"
    show_ufw_usage
}

main
