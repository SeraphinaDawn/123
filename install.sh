#!/bin/bash

# 下载 cleaner.sh
curl -sS -O https://raw.githubusercontent.com/SeraphinaDawn/123/main/cleaner.sh && chmod +x cleaner.sh

# 下载 delete_ufw_rules.sh
curl -sS -O https://raw.githubusercontent.com/SeraphinaDawn/123/main/delete_ufw_rules.sh && chmod +x delete_ufw_rules.sh

echo "脚本下载完成，您可以通过以下命令执行："
echo "1. 清理系统：./cleaner.sh"
echo "2. 删除 UFW 规则：./delete_ufw_rules.sh"
