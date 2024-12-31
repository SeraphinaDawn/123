#!/bin/bash

# =========================================================
#    灵活化安装脚本：将子脚本存放在与 install.sh 同目录下
#    并在 ~/.bashrc 中添加正确的别名指向这些脚本
# =========================================================

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # 无颜色

# 必须以 root 身份执行
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}请使用 root 用户或通过 sudo 运行此脚本。${NC}"
    exit 1
fi

# 获取本脚本所在目录的绝对路径（与 install.sh 放一起）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 安装 ufw（若已安装则跳过）
install_ufw() {
    if ! command -v ufw &> /dev/null; then
        echo -e "${YELLOW}未检测到 ufw 防火墙，正在安装...${NC}"
        if command -v apt &> /dev/null; then
            apt update && apt install ufw -y
        elif command -v yum &> /dev/null; then
            yum install epel-release -y
            yum install ufw -y
        elif command -v dnf &> /dev/null; then
            dnf install ufw -y
        else
            echo -e "${RED}无法安装 ufw，请手动安装后重试。${NC}"
            exit 1
        fi
        echo -e "${GREEN}ufw 安装完成！${NC}"
    else
        echo -e "${BLUE}ufw 已安装，无需重复安装。${NC}"
    fi
}

# 添加/更新别名到 ~/.bashrc
add_alias() {
    local name="$1"
    local command="$2"
    # 如果 ~/.bashrc 有同名别名，删除旧别名再追加
    sed -i "/alias $name=/d" ~/.bashrc
    echo "alias $name='$command'" >> ~/.bashrc
    echo -e "${GREEN}别名 '$name' 已添加到 ~/.bashrc！${NC}"
}

# 创建 cleaner.sh 脚本
create_cleaner() {
    cat << 'EOF' > "${SCRIPT_DIR}/cleaner.sh"
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
    apt-get autoclean -y > /dev/null
    apt-get clean -y > /dev/null
elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
    echo "清理 YUM/DNF 缓存..."
    yum clean all > /dev/null 2>&1 || dnf clean all > /dev/null 2>&1
else
    echo "未检测到支持的包管理器，跳过缓存清理。"
fi

echo "清理系统日志..."
journalctl --vacuum-time=7d > /dev/null
find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;

echo "清理完成！"
EOF
    chmod +x "${SCRIPT_DIR}/cleaner.sh"
    echo -e "${GREEN}cleaner.sh 脚本创建完成！${NC}"
}

# 创建 allow_ufw_port.sh 脚本
create_allow_ufw_port() {
    cat << 'EOF' > "${SCRIPT_DIR}/allow_ufw_port.sh"
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

port_number="$1"
if ufw status | grep -q "\b$port_number\b"; then
    echo "端口 [$port_number] 已放行，无需重复操作。"
else
    echo "正在放行端口 [$port_number]..."
    ufw allow "$port_number"
    echo "端口 [$port_number] 已成功放行！"
fi
EOF
    chmod +x "${SCRIPT_DIR}/allow_ufw_port.sh"
    echo -e "${GREEN}allow_ufw_port.sh 脚本创建完成！${NC}"
}

# 创建 delete_ufw_rules.sh 脚本
create_delete_ufw_rules() {
    cat << 'EOF' > "${SCRIPT_DIR}/delete_ufw_rules.sh"
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
ufw status numbered

read -p "请输入要删除的端口号（例如：80）： " port_number

if ufw status numbered | grep -q "\b$port_number\b"; then
    echo "检测到端口 [$port_number] 的规则，正在删除..."
    # 循环删除所有与该端口相关的规则
    while ufw status numbered | grep -q "\b$port_number\b"; do
        rule_number=$(ufw status numbered | grep "\b$port_number\b" | awk -F'[][]' '{print $2}' | head -n 1)
        ufw delete "$rule_number"
    done
    echo "所有与端口 [$port_number] 相关的规则已删除！"
else
    echo "未检测到与端口 [$port_number] 相关的规则，无需删除。"
fi
EOF
    chmod +x "${SCRIPT_DIR}/delete_ufw_rules.sh"
    echo -e "${GREEN}delete_ufw_rules.sh 脚本创建完成！${NC}"
}

# 用于输出一些使用提示
show_usage() {
    echo -e "${BLUE}\n==================== 使用提示 ====================${NC}"
    echo -e "${GREEN}1. 脚本已放在：${NC}"
    echo "   $SCRIPT_DIR/install.sh"
    echo -e "${GREEN}2. 子脚本已生成到：${NC}"
    echo "   $SCRIPT_DIR/cleaner.sh"
    echo "   $SCRIPT_DIR/allow_ufw_port.sh"
    echo "   $SCRIPT_DIR/delete_ufw_rules.sh"
    echo -e "${GREEN}3. 可用别名：${NC}"
    echo -e "   ${YELLOW}clea${NC}  -> 运行 ${CYAN}bash $SCRIPT_DIR/cleaner.sh${NC}"
    echo -e "   ${YELLOW}allow${NC} -> 运行 ${CYAN}bash $SCRIPT_DIR/allow_ufw_port.sh [端口]${NC}"
    echo -e "   ${YELLOW}ufw${NC}   -> 运行 ${CYAN}bash $SCRIPT_DIR/delete_ufw_rules.sh${NC}"
    echo -e "${GREEN}4. 若要使用别名，请执行：${NC}"
    echo "   source ~/.bashrc"
    echo -e "${GREEN}5. 然后您就可以使用:${NC}"
    echo -e "   ${CYAN}clea${NC}, ${CYAN}allow 443${NC}, ${CYAN}ufw${NC}"
    echo -e "${BLUE}===============================================${NC}\n"

    # ============ 原封不动的 CentOS 注意事项 =============
    echo -e "${BLUE}========================== CentOS 注意 ==========================${NC}"
    echo -e "${GREEN}如果使用 CentOS，请按照以下步骤操作：${NC}"
    echo -e "${YELLOW}1. 禁用 firewalld 防火墙：${NC}"
    echo -e "${CYAN}   sudo systemctl stop firewalld${NC}"
    echo -e "${CYAN}   sudo systemctl disable firewalld${NC}"
    echo -e "${YELLOW}2. 启用 UFW 防火墙：${NC}"
    echo -e "${CYAN}   sudo systemctl enable ufw${NC}"
    echo -e "${CYAN}   sudo systemctl start ufw${NC}"
    echo -e "${GREEN}所有操作完成！请运行以下命令使别名生效：${NC} ${CYAN}source ~/.bashrc${NC}"
    echo -e "${BLUE}=============================================================${NC}\n"
}

main() {
    echo -e "${BLUE}正在安装和配置 ufw 及各个脚本...${NC}"
    install_ufw

    # 创建 3 个子脚本
    create_cleaner
    create_allow_ufw_port
    create_delete_ufw_rules

    # 别名写入 ~/.bashrc
    add_alias clea  "bash $SCRIPT_DIR/cleaner.sh"
    add_alias allow "bash $SCRIPT_DIR/allow_ufw_port.sh"
    add_alias ufw   "bash $SCRIPT_DIR/delete_ufw_rules.sh"

    echo -e "${GREEN}所有脚本创建完毕，别名配置已写入 ~/.bashrc！${NC}"
    show_usage
}

main
echo
