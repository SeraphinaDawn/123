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

# 创建 allow_ufw_port.sh 脚本
create_allow_ufw_port() {
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
    echo -e "${GREEN}allow 脚本创建完成，并已放置到 /usr/local/bin 目录中！${NC}"
}

# 显示 UFW 配置使用说明
show_ufw_usage() {
    echo
    echo -e "${BLUE}========================== 使用提示 ==========================${NC}"
    echo -e "${GREEN}UFW 防火墙配置完成！如果尚未启用，请按照以下步骤操作：${NC}"
    echo -e "${YELLOW}1. 默认允许 SSH 端口（22）：${NC} ${CYAN}sudo ufw allow ssh${NC}"
    echo -e "${YELLOW}2. 如果更改过 SSH 端口，请放行新的端口：${NC} ${CYAN}sudo ufw allow <端口>${NC}"
    echo -e "${YELLOW}3. 启用 UFW 防火墙：${NC} ${CYAN}sudo ufw enable${NC}"
    echo -e "${YELLOW}4. 使用别名放行端口，例如放行 443 端口：${NC} ${CYAN}allow 443${NC}"
    echo -e "${GREEN}所有操作完成！请运行以下命令使别名生效： source ~/.bashrc。${NC}"
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
    echo -e "${GREEN}所有操作完成！请运行以下命令使别名生效： source ~/.bashrc。${NC}"
    echo -e "${BLUE}=============================================================${NC}"
}

# 主安装流程
main() {
    echo -e "${BLUE}正在安装和配置必要内容...${NC}"
    install_ufw
    create_allow_ufw_port

    echo -e "${GREEN}所有操作完成！${NC}"
    show_ufw_usage
}

main
