# bvservere 一键部署

## 快速开始

执行以下命令进入管理菜单：

```bash
bash <(curl -fsSL bv.2024921.xyz)
```

如果服务器未安装 Docker，按提示选择自动安装。

## 管理菜单

```text
1. 安装 / 更新
2. 配置 Docker 镜像加速
3. 启动
4. 停止
5. 重启
6. 查看状态
7. 查看日志
8. 查看访问信息
9. 设置快捷键
10. 更新管理脚本
11. 删除容器（保留数据）
0. 退出
```

## 功能说明

### 1. 安装 / 更新

拉取并运行 Docker 镜像：

```text
99320/bvservere:5.1.17
```

首次部署和更新服务都选择此项。

### 2. 配置 Docker 镜像加速

适用于国内服务器。脚本会写入 Docker Registry Mirror 并重启 Docker。

可选择推荐地址或手动输入地址。

### 3. 启动

启动已创建但当前停止的容器。

### 4. 停止

停止 `bvservere` 容器。

### 5. 重启

重启 `bvservere` 容器。

### 6. 查看状态

查看容器运行状态。

### 7. 查看日志

查看最近日志并持续跟踪。按 `Ctrl+C` 返回。

### 8. 查看访问信息

查看网页客户端和运管中心的访问地址、账号和密码。

### 9. 设置快捷键

输入快捷键名称，例如：

```text
b
```

设置完成后，在任意目录输入 `b` 即可进入管理菜单。

也可以设置为其他名称，例如：

```text
bv
```

### 10. 更新管理脚本

从 GitHub 获取最新脚本并进行语法检查。此操作只更新管理脚本，不会删除容器或业务数据。

### 11. 删除容器（保留数据）

删除容器，但保留配置和业务数据。之后可再次选择 `1` 重新部署。

## 访问地址

部署成功后，脚本会自动获取公网 IPv4，并显示：

```text
网页客户端：http://公网IP:9780
运管中心：http://公网IP:9780/center/
```

默认账号：

```text
网页客户端：admin / 123456
运管中心：superadmin / 123456
```

首次登录后请立即修改默认密码。

访问信息保存位置：

```text
/opt/bvservere/access-info.txt
```

## 默认配置

| 配置项 | 默认值 |
|---|---|
| 镜像 | `99320/bvservere:5.1.17` |
| 容器名称 | `bvservere` |
| 数据目录 | `/opt/bvservere` |
| 配置目录 | `/opt/bvservere/config` |
| 业务数据目录 | `/opt/bvservere/data` |
| 网络模式 | `host` |
| 重启策略 | `always` |
| 镜像架构 | `linux/amd64` |

## 数据目录

```text
/opt/bvservere/config  ->  /etc/servere
/opt/bvservere/data    ->  /var/bvdata
```

## 自定义数据目录

```bash
DATA_DIR=/data/bvservere bash <(curl -fsSL bv.2024921.xyz)
```

## 国内服务器

国内服务器可在菜单中选择：

```text
2. 配置 Docker 镜像加速
```

也可以将镜像同步到国内容器仓库后使用。

## 更新脚本

菜单中选择：

```text
10. 更新管理脚本
```

更新完成后，重新输入已设置的快捷键即可使用最新版本。

## 系统要求

- Linux
- `amd64/x86_64` 架构
- 可访问 GitHub 和 Docker Hub
- root 权限或 Docker 操作权限

## 数据备份

```bash
sudo tar -czf bvservere-backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /opt bvservere
```

