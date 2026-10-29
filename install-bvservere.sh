#!/usr/bin/env bash

set -Eeuo pipefail

APP_NAME="bvservere"
IMAGE="${IMAGE:-99320/bvservere:5.1.17}"
DATA_DIR="${DATA_DIR:-/opt/bvservere}"

info() { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; }

install_docker() {
    if [ "$(id -u)" -ne 0 ]; then
        error "自动安装 Docker 需要 root 权限，请使用 sudo 运行脚本。"
        exit 1
    fi

    info "正在安装 Docker..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y docker.io
        systemctl enable --now docker 2>/dev/null || service docker start 2>/dev/null || true
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y docker
        systemctl enable --now docker 2>/dev/null || true
    elif command -v yum >/dev/null 2>&1; then
        yum install -y docker
        systemctl enable --now docker 2>/dev/null || true
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache docker
        rc-update add docker default 2>/dev/null || true
        service docker start 2>/dev/null || true
    else
        error "无法识别当前系统，请手动安装 Docker。"
        exit 1
    fi
}

check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo
        echo "未检测到 Docker。"
        read -r -p "是否自动安装 Docker？[Y/n]：" answer
        case "${answer:-Y}" in
            n|N) error "未安装 Docker，脚本退出。"; exit 1 ;;
            *) install_docker ;;
        esac
    fi

    if ! docker info >/dev/null 2>&1; then
        systemctl start docker 2>/dev/null || service docker start 2>/dev/null || true
    fi

    docker info >/dev/null 2>&1 || {
        error "Docker 未运行，请手动启动 Docker 后重试。"
        exit 1
    }
}

prepare_dirs() {
    mkdir -p "$DATA_DIR/config" "$DATA_DIR/data"
    chmod 777 "$DATA_DIR/config" "$DATA_DIR/data" 2>/dev/null || true
}

exists() { docker container inspect "$APP_NAME" >/dev/null 2>&1; }
running() { [ "$(docker inspect -f '{{.State.Running}}' "$APP_NAME" 2>/dev/null || true)" = "true" ]; }

pull_image() {
    info "正在拉取镜像：$IMAGE"
    docker pull "$IMAGE"
}

start_container() {
    prepare_dirs
    docker run -itd \
        --name "$APP_NAME" \
        --restart=always \
        --user "$(id -u):$(id -g)" \
        --cap-add=NET_RAW \
        -v /etc/localtime:/etc/localtime:ro \
        -v /etc/ssl:/etc/ssl:ro \
        -v "$DATA_DIR/config:/etc/servere" \
        -v "$DATA_DIR/data:/var/bvdata" \
        --network=host \
        "$IMAGE" >/dev/null
    info "启动成功"
}

install_app() {
    pull_image
    exists && docker rm -f "$APP_NAME" >/dev/null 2>&1 || true
    start_container
}

show_menu() {
    clear 2>/dev/null || true
    echo "======================================"
    echo "       bvservere 一键管理脚本"
    echo "======================================"
    echo "镜像：$IMAGE"
    echo "数据目录：$DATA_DIR"
    echo
    echo "1. 安装 / 更新"
    echo "2. 启动"
    echo "3. 停止"
    echo "4. 重启"
    echo "5. 查看状态"
    echo "6. 查看日志"
    echo "7. 删除容器（保留数据）"
    echo "0. 退出"
    echo "======================================"
}

run_menu() {
    while true; do
        show_menu
        read -r -p "请输入选项 [0-7]：" choice
        echo
        case "$choice" in
            1)
                check_docker
                install_app
                ;;
            2)
                check_docker
                if exists; then docker start "$APP_NAME" >/dev/null; info "启动成功"; else error "容器不存在，请先选择 1 安装"; fi
                ;;
            3)
                check_docker
                if running; then docker stop "$APP_NAME" >/dev/null; fi
                info "已停止"
                ;;
            4)
                check_docker
                if exists; then docker restart "$APP_NAME" >/dev/null; info "重启成功"; else error "容器不存在，请先选择 1 安装"; fi
                ;;
            5)
                check_docker
                docker ps -a --filter "name=^/${APP_NAME}$"
                ;;
            6)
                check_docker
                if exists; then docker logs -tf --tail 30 "$APP_NAME"; else error "容器不存在"; fi
                ;;
            7)
                check_docker
                if exists; then docker rm -f "$APP_NAME" >/dev/null; fi
                info "容器已删除，数据仍保留在：$DATA_DIR"
                ;;
            0)
                echo "已退出"
                exit 0
                ;;
            *)
                error "无效选项"
                ;;
        esac
        echo
        read -r -p "按回车键返回菜单..." _
    done
}

check_docker
run_menu

