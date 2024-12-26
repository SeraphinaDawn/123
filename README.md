# 一键脚本

> 应该已经适配
> <span style="color:#FF0000;"> **Debian/Ubuntu 和 CentOS/RHEL** </span>
>
> 如果有报错,不能自行决绝的请发邮箱提交报错消息
> `xan13790@gmail.com`

## 📄 使用方法

### 地址一👇

> 直接运行以下命令即可下载并执行安装脚本：

```bash
curl -L https://raw.githubusercontent.com/SeraphinaDawn/123/main/install.sh -o install.sh && chmod +x install.sh && ./install.sh
```

### 地址二👇

```bash
curl -L https://gitee.com/ActonT/123/raw/main/install.sh -o install.sh && chmod +x install.sh && ./install.sh
```



> **安装完成后，以下快捷命令可用：**

- **clea：运行系统清理脚本，释放磁盘空间。**


- **ufw：运行防火墙规则管理脚本，一键删除指定规则。**



## 📌 注意事项

**脚本下载命令已经配置了权限,下载后请在`root`用户下运行**



## ⚠注意事项二

**如果你的系统是CentOS的系统需要禁用`firewalld` 再使用 `ufw`**

> 因为 CentOS 默认就是使用 `firewalld`

### 如果你希望禁用 `firewalld`，并使用 `ufw`

<span style="color:#FF0000;">如果你希望继续使用 `ufw`，你需要先禁用 `firewalld` 并启用 `ufw`。但是，这不推荐在生产环境中使用。</span>

**禁用 `firewalld`：**

```shell
sudo systemctl stop firewalld
sudo systemctl disable firewalld
```

**使用`ufw`**:

```shell
sudo systemctl enable ufw
sudo systemctl start ufw
```

**后面安装一键脚本的结尾提示,进行放行端口**:
