#!/usr/bin/env bash

set -Eeuo pipefail

# 支持：bash <(curl -sL https://你的域名/install-bvservere.sh)

APP_NAME="bvservere"
IMAGE="${IMAGE:-99320/bvservere:5.1.17}"
DATA_DIR="${DATA_DIR:-/opt/bvservere}"
SHORTCUT_KEY="${SHORTCUT_KEY:-b}"

info() { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; }

get_server_ip() {
    local ip=""

    # 通过公网服务获取公网 IPv4，避免显示 10.x、172.16-31.x、192.168.x 等私有地址。
    command -v curl >/dev/null 2>&1 || { echo "未获取到公网IP"; return 0; }
    for service in https://api.ipify.org https://ifconfig.me/ip https://ipv4.icanhazip.com; do
        ip=$(curl -4fsS --max-time 5 "$service" 2>/dev/null | tr -d "[:space:]" || true)
        if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            echo "$ip"
            return 0
        fi
    done

    echo "未获取到公网IP"
    return 0
}
show_access_info() {
    local ip
    ip=$(get_server_ip)
    echo
    echo "======================================"
    echo "       bvservere 部署完成"
    echo "======================================"
    echo "服务器 IP：$ip"
    echo
    echo "【网页客户端】"
    echo "访问地址：http://$ip:9780"
    echo "账号：admin"
    echo "密码：123456"
    echo
    echo "【运管中心】"
    echo "访问地址：http://$ip:9780/center/"
    echo "账号：superadmin"
    echo "密码：123456"
    echo
    echo "安全提示：首次登录后请立即修改默认密码。"
    echo "======================================"
}

save_access_info() {
    local ip file
    ip=$(get_server_ip)
    file="$DATA_DIR/access-info.txt"
    mkdir -p "$DATA_DIR"
    cat > "$file" <<EOF
bvservere 访问信息
生成时间：$(date '+%Y-%m-%d %H:%M:%S')
服务器 IP：$ip

网页客户端：
访问地址：http://$ip:9780
账号：admin
密码：123456

运管中心：
访问地址：http://$ip:9780/center/
账号：superadmin
密码：123456

请首次登录后立即修改默认密码。
EOF
    chmod 600 "$file" 2>/dev/null || true
    info "访问信息已保存：$file"
}

install_docker() {
    [ "$(id -u)" -eq 0 ] || { error "自动安装 Docker 需要 root 权限，请使用 sudo 运行。"; return 1; }
    info "开始自动安装 Docker..."
    if command -v apt-get >/dev/null 2>&1; then apt-get update && apt-get install -y docker.io
    elif command -v dnf >/dev/null 2>&1; then dnf install -y docker
    elif command -v yum >/dev/null 2>&1; then yum install -y docker
    elif command -v apk >/dev/null 2>&1; then apk add --no-cache docker
    else error "无法识别系统，请手动安装 Docker。"; return 1; fi
    systemctl enable docker 2>/dev/null || true
    systemctl start docker 2>/dev/null || service docker start 2>/dev/null || true
    command -v docker >/dev/null 2>&1 || { error "Docker 安装失败。"; return 1; }
    info "Docker 安装完成。"
}

check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        clear 2>/dev/null || true
        echo "======================================"
        echo "       未检测到 Docker"
        echo "======================================"
        echo "1. 自动安装 Docker"
        echo "2. 退出"
        echo "======================================"
        printf "请输入选项 [1-2]："
        read -r choice </dev/tty || exit 1
        case "$choice" in 1) install_docker || exit 1;; 2) error "已退出。"; exit 1;; *) error "无效选项：$choice"; exit 1;; esac
    fi
    if ! docker info >/dev/null 2>&1; then systemctl start docker 2>/dev/null || service docker start 2>/dev/null || true; fi
    docker info >/dev/null 2>&1 || { error "Docker 未运行，请手动启动后重试。"; exit 1; }
}

prepare_dirs() { mkdir -p "$DATA_DIR/config" "$DATA_DIR/data"; chmod 777 "$DATA_DIR/config" "$DATA_DIR/data" 2>/dev/null || true; }
exists() { docker container inspect "$APP_NAME" >/dev/null 2>&1; }
running() { [ "$(docker inspect -f '{{.State.Running}}' "$APP_NAME" 2>/dev/null || true)" = "true" ]; }
pull_image() { info "正在拉取镜像：$IMAGE"; docker pull "$IMAGE"; }
start_container() { prepare_dirs; docker run -itd --name "$APP_NAME" --restart=always --user "$(id -u):$(id -g)" --cap-add=NET_RAW -v /etc/localtime:/etc/localtime:ro -v /etc/ssl:/etc/ssl:ro -v "$DATA_DIR/config:/etc/servere" -v "$DATA_DIR/data:/var/bvdata" --network=host "$IMAGE" >/dev/null; info "容器启动成功"; }
install_app() { pull_image; exists && docker rm -f "$APP_NAME" >/dev/null 2>&1 || true; start_container; save_access_info; show_access_info; }

install_shortcut() {
    local target="/usr/local/bin/bvservere"
    local shortcut="${1:-b}"
    [ "$(id -u)" -eq 0 ] || { error "设置快捷键需要 root 权限，请使用 sudo 运行。"; return 1; }
    if [[ ! "$shortcut" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error "快捷键只能包含字母、数字、下划线或短横线。"
        return 1
    fi
    cat > "$target" <<'EOF'
#!/usr/bin/env bash
exec bash -c "$(curl -fsSL https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh)" -- "$@"
EOF
    chmod 755 "$target"
    ln -sfn "$target" "/usr/local/bin/$shortcut"
    info "快捷键已设置：$shortcut"
    info "以后在任意目录输入 $shortcut 即可进入菜单。"
}

update_script() {
    local target="/usr/local/bin/bvservere"
    [ "$(id -u)" -eq 0 ] || { error "更新脚本需要 root 权限，请使用 sudo 运行。"; return 1; }
    command -v curl >/dev/null 2>&1 || { error "未找到 curl，无法更新脚本。"; return 1; }
    info "正在从 GitHub 更新管理脚本..."
    local tmp
    tmp=$(mktemp)
    if curl -4fsSL --connect-timeout 10 --max-time 60 "https://raw.githubusercontent.com/kejiland/bvservere/main/install-bvservere.sh" -o "$tmp" && [ -s "$tmp" ]; then
        if bash -n "$tmp"; then
            install -m 755 "$tmp" "$target"
            rm -f "$tmp"
            info "脚本更新成功。"
            info "以后输入快捷键即可使用最新版本。"
        else
            rm -f "$tmp"
            error "下载的脚本语法检查失败，已保留当前版本。"
            return 1
        fi
    else
        rm -f "$tmp"
        error "脚本下载失败，请检查网络。"
        return 1
    fi
}
configure_registry_mirror() {
    check_docker
    local config="/etc/docker/daemon.json"
    local mirror="https://docker.m.daocloud.io"
    echo "Docker 镜像加速配置"
    echo "1. DaoCloud 公共加速地址"
    echo "2. 手动输入加速地址"
    echo "3. 取消"
    printf "请输入选项 [1-3]："
    read -r mirror_choice </dev/tty || return 1
    case "$mirror_choice" in
        1) mirror="https://docker.m.daocloud.io" ;;
        2) printf "请输入镜像加速地址："; read -r mirror </dev/tty; [ -n "$mirror" ] || { error "地址不能为空"; return 1; } ;;
        3) return 0 ;;
        *) error "无效选项"; return 1 ;;
    esac
    mkdir -p /etc/docker
    local backup="/etc/docker/daemon.json.bak.$(date +%Y%m%d%H%M%S)"
    [ -f "$config" ] && cp "$config" "$backup"
    cat > "$config" <<EOF
{
  "registry-mirrors": ["$mirror"]
}
EOF
    systemctl daemon-reload 2>/dev/null || true
    systemctl restart docker
    info "Docker 镜像加速已配置：$mirror"
    info "原配置备份：${backup:-无}"
    docker info 2>/dev/null | grep -A5 -i "Registry Mirrors" || true
}
set_shortcut() {
    local shortcut
    printf "请输入快捷键名称（直接回车使用 b）："
    read -r shortcut </dev/tty || return 1
    shortcut="${shortcut:-b}"
    install_shortcut "$shortcut"
}
show_menu() { clear 2>/dev/null || true; echo "======================================"; echo "       bvservere 一键管理脚本"; echo "======================================"; echo "镜像：$IMAGE"; echo "数据目录：$DATA_DIR"; echo; echo "1. 安装 / 更新"; echo "2. 配置 Docker 镜像加速"; echo "3. 启动"; echo "4. 停止"; echo "5. 重启"; echo "6. 查看状态"; echo "7. 查看日志"; echo "8. 查看访问信息"; echo "9. 设置快捷键"; echo "10. 更新管理脚本"; echo "11. 删除容器（保留数据）"; echo "0. 退出"; echo; echo "快捷键：$SHORTCUT_KEY  启动/进入此管理脚本"; echo "======================================"; }
run_menu() { while true; do show_menu; printf "请输入选项 [0-11]："; read -r choice </dev/tty || exit 1; echo; case "$choice" in 1) check_docker; install_app; install_shortcut;; 2) configure_registry_mirror;; 3) check_docker; exists && docker start "$APP_NAME" >/dev/null && info "启动成功" || error "容器不存在，请先选择 1 安装";; 4) check_docker; running && docker stop "$APP_NAME" >/dev/null || true; info "已停止";; 5) check_docker; exists && docker restart "$APP_NAME" >/dev/null && info "重启成功" || error "容器不存在，请先选择 1 安装";; 6) check_docker; docker ps -a --filter "name=^/${APP_NAME}$";; 7) check_docker; exists && docker logs -tf --tail 30 "$APP_NAME" || error "容器不存在";; 8) show_access_info; echo; printf "按回车键返回菜单..."; read -r _ </dev/tty;; 9) set_shortcut;; 10) update_script;; 11) check_docker; exists && docker rm -f "$APP_NAME" >/dev/null || true; info "容器已删除，数据仍保留在：$DATA_DIR";; 0) exit 0;; *) error "无效选项";; esac; if [ "$choice" != 7 ]; then echo; printf "按回车键返回菜单..."; read -r _ </dev/tty; fi; done; }

check_docker
run_menu













