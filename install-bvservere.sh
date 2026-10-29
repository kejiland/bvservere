#!/usr/bin/env bash

set -Eeuo pipefail

APP_NAME="bvservere"
IMAGE="${IMAGE:-99320/bvservere:5.1.17}"
DATA_DIR="${DATA_DIR:-/opt/bvservere}"

info() { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; }

install_docker() {
    [ "$(id -u)" -eq 0 ] || { error "自动安装 Docker 需要 root 权限，请使用 sudo 运行。"; return 1; }
    info "开始自动安装 Docker..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y docker.io
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y docker
    elif command -v yum >/dev/null 2>&1; then
        yum install -y docker
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache docker
    else
        error "无法识别系统，请手动安装 Docker。"
        return 1
    fi
    systemctl enable docker 2>/dev/null || true
    systemctl start docker 2>/dev/null || service docker start 2>/dev/null || true
    command -v docker >/dev/null 2>&1 || { error "Docker 安装失败。"; return 1; }
    info "Docker 安装完成。"
}

check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo
        echo "未检测到 Docker。"
        echo "1. 自动安装 Docker"
        echo "2. 退出"
        while true; do
            read -r -p "请输入选项 [1-2]：" choice
            case "$choice" in
                1) install_docker || exit 1; break ;;
                2) error "已退出。"; exit 1 ;;
                *) echo "请输入 1 或 2。" ;;
            esac
        done
    fi
    if ! docker info >/dev/null 2>&1; then
        systemctl start docker 2>/dev/null || service docker start 2>/dev/null || true
    fi
    docker info >/dev/null 2>&1 || { error "Docker 未运行，请手动启动后重试。"; exit 1; }
}

prepare_dirs() { mkdir -p "$DATA_DIR/config" "$DATA_DIR/data"; chmod 777 "$DATA_DIR/config" "$DATA_DIR/data" 2>/dev/null || true; }
exists() { docker container inspect "$APP_NAME" >/dev/null 2>&1; }
running() { [ "$(docker inspect -f '{{.State.Running}}' "$APP_NAME" 2>/dev/null || true)" = "true" ]; }
pull_image() { info "正在拉取镜像：$IMAGE"; docker pull "$IMAGE"; }
start_container() { prepare_dirs; docker run -itd --name "$APP_NAME" --restart=always --user "$(id -u):$(id -g)" --cap-add=NET_RAW -v /etc/localtime:/etc/localtime:ro -v /etc/ssl:/etc/ssl:ro -v "$DATA_DIR/config:/etc/servere" -v "$DATA_DIR/data:/var/bvdata" --network=host "$IMAGE" >/dev/null; info "启动成功"; }
install_app() { pull_image; exists && docker rm -f "$APP_NAME" >/dev/null 2>&1 || true; start_container; }
show_menu() { clear 2>/dev/null || true; echo "======================================"; echo "       bvservere 一键管理脚本"; echo "======================================"; echo "镜像：$IMAGE"; echo "数据目录：$DATA_DIR"; echo; echo "1. 安装 / 更新"; echo "2. 启动"; echo "3. 停止"; echo "4. 重启"; echo "5. 查看状态"; echo "6. 查看日志"; echo "7. 删除容器（保留数据）"; echo "0. 退出"; echo "======================================"; }
run_menu() { while true; do show_menu; read -r -p "请输入选项 [0-7]：" choice; echo; case "$choice" in 1) check_docker; install_app;; 2) check_docker; exists && docker start "$APP_NAME" >/dev/null && info "启动成功" || error "容器不存在，请先选择 1 安装";; 3) check_docker; running && docker stop "$APP_NAME" >/dev/null || true; info "已停止";; 4) check_docker; exists && docker restart "$APP_NAME" >/dev/null && info "重启成功" || error "容器不存在，请先选择 1 安装";; 5) check_docker; docker ps -a --filter "name=^/${APP_NAME}$";; 6) check_docker; exists && docker logs -tf --tail 30 "$APP_NAME" || error "容器不存在";; 7) check_docker; exists && docker rm -f "$APP_NAME" >/dev/null || true; info "容器已删除，数据仍保留在：$DATA_DIR";; 0) exit 0;; *) error "无效选项";; esac; echo; read -r -p "按回车键返回菜单..." _; done; }

check_docker
run_menu
