#!/usr/bin/env bash

set -Eeuo pipefail

APP_NAME="bvservere"
IMAGE="${IMAGE:-99320/bvservere:5.1.17}"
DATA_DIR="${DATA_DIR:-/opt/bvservere}"

log() {
    printf '[INFO] %s\n' "$*"
}

warn() {
    printf '[WARN] %s\n' "$*" >&2
}

fail() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

require_docker() {
    command -v docker >/dev/null 2>&1 || fail '未找到 Docker，请先安装 Docker。'
    docker info >/dev/null 2>&1 || fail 'Docker 服务未运行，请先启动 Docker。'
}

prepare_dirs() {
    mkdir -p "$DATA_DIR/config" "$DATA_DIR/data"
    chmod 777 "$DATA_DIR/config" "$DATA_DIR/data" 2>/dev/null || \
        warn "无法设置目录权限为 777，请确认当前用户权限。"
}

pull_image() {
    log "拉取镜像：$IMAGE"
    docker pull "$IMAGE"
}

container_exists() {
    docker container inspect "$APP_NAME" >/dev/null 2>&1
}

container_running() {
    [ "$(docker inspect -f '{{.State.Running}}' "$APP_NAME" 2>/dev/null || true)" = "true" ]
}

remove_container() {
    if container_exists; then
        log "删除旧容器：$APP_NAME"
        docker rm -f "$APP_NAME" >/dev/null
    fi
}

run_container() {
    prepare_dirs

    log "启动容器：$APP_NAME"
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

    log '容器启动成功。'
}

install_or_update() {
    pull_image
    remove_container
    run_container
}

usage() {
    cat <<EOF
用法：
  sudo $0 install      首次安装或重新部署
  sudo $0 update       拉取镜像并更新容器
  sudo $0 pull         仅拉取镜像
  sudo $0 start        启动已有容器
  sudo $0 stop         停止容器
  sudo $0 restart      重启容器
  sudo $0 status       查看容器状态
  sudo $0 logs         查看日志
  sudo $0 uninstall    删除容器，保留数据目录

可选环境变量：
  IMAGE=99320/bvservere:5.1.17
  DATA_DIR=/opt/bvservere
EOF
}

main() {
    require_docker

    case "${1:-}" in
        install|update)
            install_or_update
            ;;
        pull)
            pull_image
            ;;
        start)
            container_exists || fail '容器不存在，请先执行 install。'
            docker start "$APP_NAME" >/dev/null
            log '容器已启动。'
            ;;
        stop)
            if container_running; then
                docker stop "$APP_NAME" >/dev/null
            fi
            log '容器已停止。'
            ;;
        restart)
            container_exists || fail '容器不存在，请先执行 install。'
            docker restart "$APP_NAME" >/dev/null
            log '容器已重启。'
            ;;
        status)
            docker ps -a --filter "name=^/${APP_NAME}$"
            ;;
        logs)
            docker logs -tf --tail 30 "$APP_NAME"
            ;;
        uninstall)
            remove_container
            log "已删除容器，数据仍保留在：$DATA_DIR"
            ;;
        help|-h|--help|'')
            usage
            ;;
        *)
            usage
            exit 2
            ;;
    esac
}

main "$@"
