#!/bin/bash

set -e

REPO="mand-byte/AutoBuildOpenWrtDockerImage"
ARTIFACT_PREFIX="openwrt-nas-docker-image-"
DATE_TAG="$1"
TAR_FILE=""
DOWNLOAD_DIR="./"
COMPOSE_FILE="docker-compose.yml"

api_url="https://api.github.com/repos/$REPO/releases"

if [ -z "$DATE_TAG" ]; then
  echo "未指定日期，自动查找最新 release..."
  release_info=$(curl -s "$api_url" | jq '.[0]')
  DATE_TAG=$(echo "$release_info" | jq -r '.tag_name')
  asset_url=$(echo "$release_info" | jq -r '.assets[] | select(.name|test("x86") and endswith(".tar")) | .browser_download_url')
  TAR_FILE=$(basename "$asset_url")
else
  echo "指定日期为 $DATE_TAG，查找对应 release..."
  release_info=$(curl -s "$api_url/tags/$DATE_TAG")
  asset_url=$(echo "$release_info" | jq -r '.assets[] | select(.name|test("x86") and endswith(".tar")) | .browser_download_url')
  TAR_FILE=$(basename "$asset_url")
fi

if [ -z "$asset_url" ] || [ "$asset_url" == "null" ]; then
  echo "未找到对应的 x86 release 或 tar 文件！"
  exit 1
fi

echo "下载 release asset: $TAR_FILE ..."
curl -L -o "$TAR_FILE" "$asset_url"

echo "加载新 openwrt-nas 镜像..."
IMAGE_ID=$(docker load -i "$TAR_FILE" | grep 'Loaded image:' | awk '{print $3}')
# 获取镜像tag
NEW_TAG=$(docker image inspect --format '{{index .RepoTags 0}}' "$IMAGE_ID" | awk -F: '{print $2}')
NEW_IMAGE="openwrt-nas:$NEW_TAG"

echo "修改 $COMPOSE_FILE 中的 image 字段为 $NEW_IMAGE ..."
sed -i -E "s|image: openwrt-nas:[^ ]*|image: $NEW_IMAGE|g" "$COMPOSE_FILE"

echo "停止并删除旧 openwrt 容器..."
docker compose down || true

echo "启动 openwrt..."
if docker compose up -d; then
  echo "Compose 启动成功，准备删除旧镜像..."
  # 删除除新镜像外的 openwrt-nas 镜像
  docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep '^openwrt-nas:' | grep -v "$NEW_TAG" | awk '{print $2}' | xargs -r docker rmi -f
  echo "旧镜像已删除。"
else
  echo "Compose 启动失败，保留旧镜像。"
  exit 1
fi

echo "Done. OpenWrt is running with image version: $TAR_FILE"