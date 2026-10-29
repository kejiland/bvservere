# bvservere 使用说明

`bvservere` 是一个基于 Docker 的调度系统服务。本项目提供一键安装、升级和日常管理脚本。

## 1. 系统要求

- Linux 服务器
- `amd64/x86_64` 架构
- Docker 已安装并正在运行
- 服务器可以访问 GitHub 和 Docker Hub
- 使用 root 用户或具备 Docker 权限的用户执行

镜像地址：

```text
99320/bvservere:5.1.17
```

## 2. 一键安装

直接安装：

```bash
curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh | sudo bash -s -- install
```

更安全的方式是先下载、检查，再执行：

```bash
curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh -o install-bvservere.sh
less install-bvservere.sh
chmod +x install-bvservere.sh
sudo ./install-bvservere.sh install
```

如果当前用户已经可以直接执行 Docker，也可以不使用 `sudo`。

## 3. 常用命令

使用远程脚本执行：

```bash
# 首次安装或重新部署
curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh | sudo bash -s -- install

# 拉取镜像并更新容器
curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh | sudo bash -s -- update

# 仅拉取镜像
curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh | sudo bash -s -- pull

# 启动
curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh | sudo bash -s -- start

# 停止
curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh | sudo bash -s -- stop

# 重启
curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh | sudo bash -s -- restart

# 查看状态
curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh | sudo bash -s -- status

# 查看日志，持续跟踪最近 30 行
curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh | sudo bash -s -- logs

# 删除容器，但保留数据目录
curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh | sudo bash -s -- uninstall
```

如果已经下载脚本，也可以使用本地文件：

```bash
sudo ./install-bvservere.sh install
sudo ./install-bvservere.sh update
sudo ./install-bvservere.sh status
sudo ./install-bvservere.sh logs
```

## 4. 默认配置

| 配置项 | 默认值 |
|---|---|
| Docker 镜像 | `99320/bvservere:5.1.17` |
| 容器名称 | `bvservere` |
| 数据目录 | `/opt/bvservere` |
| 配置目录 | `/opt/bvservere/config` |
| 数据存储目录 | `/opt/bvservere/data` |
| 网络模式 | `host` |
| 容器重启策略 | `always` |
| 容器能力 | `NET_RAW` |
| 镜像架构 | `linux/amd64` |

容器内挂载关系：

```text
/opt/bvservere/config  ->  /etc/servere
/opt/bvservere/data    ->  /var/bvdata
/etc/localtime         ->  /etc/localtime
/etc/ssl               ->  /etc/ssl
```

## 5. 自定义数据目录

默认数据目录是 `/opt/bvservere`。如需改为其他目录，可以设置 `DATA_DIR`：

```bash
sudo DATA_DIR=/data/bvservere ./install-bvservere.sh install
```

使用远程脚本时：

```bash
curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh | sudo DATA_DIR=/data/bvservere bash -s -- install
```

## 6. 查看容器详情

```bash
docker ps -a --filter name=bvservere
docker inspect bvservere
docker logs -tf --tail 30 bvservere
```

进入容器：

```bash
docker exec -it bvservere sh
```

## 7. 数据和升级说明

执行 `update` 时会：

1. 从 Docker Hub 拉取 `99320/bvservere:5.1.17`；
2. 删除旧的 `bvservere` 容器；
3. 使用同一个数据目录重新创建容器。

以下目录不会因删除容器而删除：

```text
/opt/bvservere/config
/opt/bvservere/data
```

升级前建议备份：

```bash
sudo tar -czf bvservere-backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /opt bvservere
```

## 8. 常见问题

### 8.1 Docker 未运行

如果提示 Docker 服务未运行，请先启动 Docker：

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

检查：

```bash
docker info
```

### 8.2 无法拉取镜像

检查网络和 Docker Hub 登录状态：

```bash
docker login
docker pull 99320/bvservere:5.1.17
```

如果仓库为私有仓库，目标服务器必须先登录对应的 Docker Hub 账号。

### 8.3 架构不匹配

检查服务器架构：

```bash
uname -m
```

本镜像适用于：

```text
x86_64
amd64
```

不适用于没有兼容运行环境的 ARM64 服务器。

### 8.4 容器启动后立即退出

查看日志：

```bash
docker logs bvservere
```

查看状态：

```bash
sudo ./install-bvservere.sh status
```

同时检查配置目录是否存在：

```bash
ls -la /opt/bvservere/config
ls -la /opt/bvservere/data
```

## 9. 安全建议

生产环境建议先下载脚本并检查内容，再执行：

```bash
curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh -o install-bvservere.sh
less install-bvservere.sh
sudo bash install-bvservere.sh install
```

不要在脚本或命令中公开 Docker Hub 密码、访问令牌等敏感信息。
