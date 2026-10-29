# bvservere 一键部署使用说明

`bvservere` 是一个基于 Docker 的调度系统服务。本项目提供数字菜单式一键部署和管理脚本。

## 一、系统要求

- Linux 服务器
- `amd64/x86_64` 架构
- 已安装 Docker；如果未安装，脚本会提供自动安装选项
- 服务器可以访问 GitHub 和 Docker Hub
- 使用 root 用户或具备 Docker 操作权限的用户执行

Docker 镜像：

```text
99320/bvservere:5.1.17
```

镜像架构：

```text
linux/amd64
```

## 二、一键启动

执行：

```bash
curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh | sudo bash
```

如果服务器没有 Docker，脚本会显示：

```text
1. 自动安装 Docker
2. 退出
```

选择 `1` 后，脚本会根据系统自动安装并启动 Docker。

## 三、数字菜单

进入脚本后会显示：

```text
1. 安装 / 更新
2. 启动
3. 停止
4. 重启
5. 查看状态
6. 查看日志
7. 查看访问信息
8. 设置快捷键
9. 更新管理脚本
10. 删除容器（保留数据）
0. 退出
```

### 1. 安装 / 更新

拉取 `99320/bvservere:5.1.17` 镜像，删除旧容器并重新创建服务。

首次部署和更新 Docker 服务都选择此项。

### 2. 启动

启动已经创建但当前停止的容器。

### 3. 停止

停止当前运行的 `bvservere` 容器。

### 4. 重启

重启已经创建的 `bvservere` 容器。

### 5. 查看状态

查看容器是否正在运行。

### 6. 查看日志

显示最近 30 行日志并持续跟踪新的输出。按 `Ctrl+C` 可以退出日志查看。

### 7. 查看访问信息

查看网页客户端和运管中心的访问地址、账号和密码。

### 8. 设置快捷键

选择 `8` 后，输入一个快捷键名称，例如：

```text
b
```

脚本会在 `/usr/local/bin/` 创建全局命令。之后无论当前在哪个目录，直接输入：

```bash
b
```

即可进入 bvservere 管理菜单。

也可以设置为：

```text
bv
```

以后输入 `bv` 即可进入菜单。

快捷键名称只能包含字母、数字、下划线或短横线。

### 9. 更新管理脚本

选择 `9` 后，脚本会从 GitHub 下载最新版本并进行语法检查，检查通过后替换本地管理脚本。

此选项只更新管理脚本：

- 不会删除 Docker 容器；
- 不会删除配置和业务数据；
- 不会重新拉取 Docker 镜像；
- 不会主动重启 `bvservere` 服务。

如果当前快捷键已经设置，更新后继续输入快捷键即可使用最新脚本。

### 10. 删除容器（保留数据）

删除 `bvservere` 容器，但保留配置和业务数据。之后选择 `1` 可以重新部署。

### 0. 退出

退出管理菜单，不对容器执行操作。

## 四、部署完成后的访问地址

部署成功后，脚本会通过公网查询服务获取公网 IPv4，并显示：

```text
【网页客户端】
访问地址：http://公网IP:9780
账号：admin
密码：123456

【运管中心】
访问地址：http://公网IP:9780/center/
账号：superadmin
密码：123456
```

访问信息同时保存到：

```text
/opt/bvservere/access-info.txt
```

如果无法获取公网 IP，会显示：

```text
未获取到公网IP
```

注意：`172.16.0.0/12`、`10.0.0.0/8`、`192.168.0.0/16` 等属于私有地址，不会作为公网访问地址使用。

首次登录后请立即修改默认密码。

## 五、默认目录和挂载

宿主机目录：

```text
/opt/bvservere/
├── config/    配置文件
├── data/      业务数据
└── access-info.txt
```

容器挂载：

```text
/opt/bvservere/config  ->  /etc/servere
/opt/bvservere/data    ->  /var/bvdata
/etc/localtime         ->  /etc/localtime
/etc/ssl               ->  /etc/ssl
```

## 六、默认容器配置

| 配置项 | 值 |
|---|---|
| 容器名称 | `bvservere` |
| Docker 镜像 | `99320/bvservere:5.1.17` |
| 网络模式 | `host` |
| 重启策略 | `always` |
| 容器能力 | `NET_RAW` |
| 数据目录 | `/opt/bvservere` |

## 七、数据备份

更新或删除容器不会自动删除配置和业务数据。重要操作前建议备份：

```bash
sudo tar -czf bvservere-backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /opt bvservere
```

## 八、常见问题

### Docker 未安装

运行脚本后选择：

```text
1. 自动安装 Docker
```

### 无法拉取镜像

检查服务器网络。如果 Docker Hub 仓库需要登录，请先执行：

```bash
docker login
```

### 快捷键无效

确认命令是否存在：

```bash
ls -l /usr/local/bin/b
```

如果设置的是其他名称，将命令中的 `b` 替换为实际快捷键。

### 服务器架构不匹配

检查架构：

```bash
uname -m
```

当前镜像只适用于 `x86_64/amd64`。

### 容器启动后退出

在菜单中选择 `6. 查看日志`，检查启动日志和配置文件。

## 九、安全建议

生产环境建议先下载脚本、检查内容后再执行：

```bash
curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh -o install-bvservere.sh
less install-bvservere.sh
sudo bash install-bvservere.sh
```

首次登录后请立即修改默认密码，不要在公开位置保存 Docker Hub 密码或访问令牌。

## 十、短链接一键执行

本脚本支持类似下面的方式：

```bash
bash <(curl -fsSL https://你的域名/install-bvservere.sh)
```

如果使用自己的短域名，例如 `bv.example.com`，可以将域名的 HTTPS 请求转发到 GitHub Raw：

```bash
bash <(curl -fsSL https://bv.example.com)
```

也可以使用短路径：

```bash
bash <(curl -fsSL https://bv.example.com/bv)
```

### 使用 Cloudflare Worker 做短链接

可以创建一个 Cloudflare Worker，将访问 `/` 的请求转发到 GitHub Raw：

```javascript
export default {
  async fetch(request) {
    const target = "https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh";
    return fetch(target, {
      method: request.method,
      headers: request.headers,
      redirect: "follow"
    });
  }
};
```

绑定域名后即可使用：

```bash
bash <(curl -fsSL https://你的短域名)
```

### 使用 Nginx 短路径

如果你有自己的服务器和域名，可以配置：

```nginx
location = /bv {
    proxy_pass https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh;
    proxy_set_header Host raw.githubusercontent.com;
}
```

然后执行：

```bash
bash <(curl -fsSL https://你的域名/bv)
```

### 注意事项

- 短链接必须返回纯文本 Shell 脚本内容；
- 必须使用 HTTPS；
- 短链接服务需要支持重定向或代理返回；
- 生产环境建议先下载并检查脚本；
- 不要使用不可信的短链接执行脚本；
- 如果脚本需要交互输入，使用 `bash <(curl ...)` 比 `curl ... | bash` 更适合。
