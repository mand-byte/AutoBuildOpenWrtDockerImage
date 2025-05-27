#!/bin/bash

set -e

REPO="mand-byte/AutoBuildOpenWrtDockerImage"
ARTIFACT_PREFIX="openwrt-nas-docker-image-"
DATE_TAG="$1"
TAR_FILE=""
DOWNLOAD_DIR="./"

api_url="https://api.github.com/repos/$REPO/releases"

if [ -z "$DATE_TAG" ]; then
  echo "未指定日期，自动查找最新 release..."
  # 获取最新 release 的 tag 和 asset 下载链接
  release_info=$(curl -s "$api_url" | jq '.[0]')
  DATE_TAG=$(echo "$release_info" | jq -r '.tag_name')
  asset_url=$(echo "$release_info" | jq -r '.assets[] | select(.name|endswith(".tar")) | .browser_download_url')
  TAR_FILE=$(basename "$asset_url")
else
  echo "指定日期为 $DATE_TAG，查找对应 release..."
  release_info=$(curl -s "$api_url/tags/$DATE_TAG")
  asset_url=$(echo "$release_info" | jq -r '.assets[] | select(.name|endswith(".tar")) | .browser_download_url')
  TAR_FILE=$(basename "$asset_url")
fi

if [ -z "$asset_url" ] || [ "$asset_url" == "null" ]; then
  echo "未找到对应的 release 或 tar 文件！"
  exit 1
fi

echo "下载 release asset: $TAR_FILE ..."
curl -L -o "$TAR_FILE" "$asset_url"

# 停止并删除旧容器
if docker ps -a --format '{{.Names}}' | grep -q '^openwrt$'; then
  echo "Stopping and removing existing openwrt container..."
  docker compose down
fi

# 删除旧镜像（可选）
if docker images | grep -q 'openwrt-nas'; then
  echo "Removing old openwrt-nas image..."
  docker rmi -f openwrt-nas:latest || true
  if [ -n "$DATE_TAG" ]; then
    docker rmi -f openwrt-nas:$DATE_TAG || true
  fi
fi

# 加载新镜像
echo "Loading new openwrt-nas docker image..."
docker load -i "$TAR_FILE"

# 启动 compose
echo "Starting openwrt with docker-compose..."
docker compose up -d

echo "Done. OpenWrt is running with image version: $TAR_FILE"