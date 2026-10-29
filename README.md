# bvservere 一键部署使用说明

`bvservere` 是一个基于 Docker 的调度系统服务。本项目提供数字菜单式一键安装和管理脚本。

## 一、系统要求

- Linux 服务器
- `amd64/x86_64` 架构
- 已安装 Docker；如果未安装，脚本会询问是否自动安装
- 服务器可以访问 GitHub 和 Docker Hub
- 使用 root 用户，或当前用户具有 Docker 操作权限

本次使用的镜像：

```text
99320/bvservere:5.1.17
```

镜像架构：

```text
linux/amd64
```

## 二、一键运行

在服务器上执行下面一条命令：

```bash
curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh | sudo bash
```

脚本启动后会显示数字菜单：

```text
======================================
       bvservere 一键管理脚本
======================================
镜像：99320/bvservere:5.1.17
数据目录：/opt/bvservere

1. 安装 / 更新
2. 启动
3. 停止
4. 重启
5. 查看状态
6. 查看日志
7. 删除容器（保留数据）
0. 退出
======================================
请输入选项 [0-7]：
```

根据提示输入数字并按回车即可。
如果服务器未安装 Docker，脚本会显示：

```text
未检测到 Docker。
是否自动安装 Docker？[Y/n]：
```

直接按回车或输入 `Y`，脚本会根据系统的软件包管理器自动安装 Docker，并尝试启动 Docker 服务。

当前支持常见的：

- Debian / Ubuntu：`apt-get`
- CentOS / RHEL 兼容系统：`yum`
- Fedora / Rocky / AlmaLinux 等：`dnf`
- Alpine Linux：`apk`

如果输入 `n`，脚本会退出，不安装 Docker。

## 三、菜单功能

### 1. 安装 / 更新

选择 `1` 后，脚本会自动：

1. 检查 Docker 是否正常运行；
2. 从 Docker Hub 拉取 `99320/bvservere:5.1.17`；
3. 创建配置目录和数据目录；
4. 删除原有 `bvservere` 容器；
5. 使用新镜像重新创建并启动容器。

首次安装和后续更新都选择此项。

### 2. 启动

启动已经创建但当前停止的容器。

如果容器不存在，请先选择 `1` 安装。

### 3. 停止

停止当前运行的 `bvservere` 容器。

### 4. 重启

重启已经创建的 `bvservere` 容器。

### 5. 查看状态

查看容器是否正在运行，以及容器的创建时间和端口信息。

### 6. 查看日志

显示最近 30 行日志，并持续跟踪新的日志输出。

按 `Ctrl+C` 可以退出日志查看，返回系统终端；不会停止容器。

### 7. 删除容器（保留数据）

删除 `bvservere` 容器，但保留配置和业务数据。删除后如需重新部署，再次选择 `1` 即可。

### 0. 退出

退出菜单，不对容器执行任何操作。

## 四、默认目录

脚本默认使用以下目录：

```text
/opt/bvservere/
├── config/    配置文件目录
└── data/      业务数据目录
```

容器内的挂载关系：

```text
/opt/bvservere/config  ->  /etc/servere
/opt/bvservere/data    ->  /var/bvdata
```

容器还会使用：

```text
/etc/localtime  ->  /etc/localtime
/etc/ssl        ->  /etc/ssl
```

## 五、修改数据目录

如果不想使用默认的 `/opt/bvservere`，可以在运行脚本前设置 `DATA_DIR`：

```bash
DATA_DIR=/data/bvservere curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh | sudo -E bash
```

之后脚本中的数字菜单仍然不变。

## 六、容器配置

| 配置项 | 值 |
|---|---|
| 容器名称 | `bvservere` |
| Docker 镜像 | `99320/bvservere:5.1.17` |
| 数据目录 | `/opt/bvservere` |
| 网络模式 | `host` |
| 重启策略 | `always` |
| 容器能力 | `NET_RAW` |
| 用户身份 | 当前执行用户的 UID/GID |

脚本保留了原 `runbvservere.sh` 中的主要运行参数。

## 七、更新说明

当 Docker Hub 中发布了新版本镜像后，需要同步修改脚本中的镜像版本，然后选择菜单 `1` 执行更新。

当前脚本使用的版本为：

```text
5.1.17
```

更新操作不会删除以下数据：

```text
/opt/bvservere/config
/opt/bvservere/data
```

更新前建议备份数据目录：

```bash
sudo tar -czf bvservere-backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /opt bvservere
```

## 八、常见问题

### 1. Docker 未运行

请先启动 Docker 服务，然后重新执行脚本：

```bash
sudo systemctl start docker
```

### 2. 无法拉取镜像

检查服务器网络和 Docker Hub 访问情况。如果 Docker Hub 仓库为私有仓库，需要先登录：

```bash
docker login
```

### 3. 架构不匹配

检查服务器架构：

```bash
uname -m
```

返回 `x86_64` 时可以运行本镜像。`aarch64`/ARM64 服务器不能直接使用当前 amd64 镜像。

### 4. 容器启动后退出

在数字菜单中选择 `6` 查看日志，重点检查配置目录和数据目录是否有正确内容。

## 九、安全建议

推荐先下载并查看脚本内容，再执行：

```bash
curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh -o install-bvservere.sh
less install-bvservere.sh
sudo bash install-bvservere.sh
```

不要在公开位置保存 Docker Hub 密码或访问令牌。

