#!/bin/bash

set -e

# 配置你的仓库信息
REPO="mand-byte/AutoBuildOpenWrtDockerImage"
ARTIFACT_NAME="openwrt-nas-docker-image"
DOWNLOAD_DIR="./"
TAR_FILE="openwrt-nas-docker-image.tar"

# 0. 下载最新 artifact
echo "Downloading latest artifact from GitHub Actions..."
artifact_id=$(gh api -X GET "repos/$REPO/actions/artifacts" --jq '.artifacts[] | select(.name=="'"$ARTIFACT_NAME"'") | .id' | head -n1)
if [ -z "$artifact_id" ]; then
  echo "No artifact named $ARTIFACT_NAME found!"
  exit 1
fi
gh api -X GET -H "Accept: application/vnd.github+json" \
  "repos/$REPO/actions/artifacts/$artifact_id/zip" > artifact.zip

unzip -o artifact.zip -d "$DOWNLOAD_DIR"
rm artifact.zip

# 1. 停止并删除旧容器
if docker ps -a --format '{{.Names}}' | grep -q '^openwrt$'; then
  echo "Stopping and removing existing openwrt container..."
  docker compose down
fi

# 2. 删除旧镜像（可选，防止镜像堆积）
if docker images | grep -q 'openwrt-nas'; then
  echo "Removing old openwrt-nas image..."
  docker rmi -f openwrt-nas:latest || true
fi

# 3. 加载新镜像
echo "Loading new openwrt-nas docker image..."
docker load -i "$TAR_FILE"

# 4. 启动 compose
echo "Starting openwrt with docker-compose..."
docker compose up -d

echo "Done. OpenWrt is running with the latest image."
