#!/bin/bash

set -e

REPO="mand-byte/AutoBuildOpenWrtDockerImage"
ARTIFACT_PREFIX="openwrt-nas-docker-image-"
DATE_TAG="$1"
TAR_FILE=""
DOWNLOAD_DIR="./"

api_url="https://api.github.com/repos/$REPO/actions/artifacts"

if [ -z "$DATE_TAG" ]; then
  echo "未指定日期，自动查找最新 artifact..."
  # 获取最新 artifact 的下载链接和名字
  artifact_url=$(curl -s "$api_url" | jq -r '.artifacts | sort_by(.id) | reverse | .[0].archive_download_url')
  artifact_name=$(curl -s "$api_url" | jq -r '.artifacts | sort_by(.id) | reverse | .[0].name')
  TAR_FILE="${artifact_name}.tar"
else
  echo "指定日期为 $DATE_TAG，查找对应 artifact..."
  artifact_name="${ARTIFACT_PREFIX}${DATE_TAG}"
  artifact_url=$(curl -s "$api_url" | jq -r '.artifacts[] | select(.name=="'"$artifact_name"'") | .archive_download_url' | head -n1)
  TAR_FILE="${artifact_name}.tar"
fi

if [ -z "$artifact_url" ]; then
  echo "未找到对应的 artifact！"
  exit 1
fi

echo "下载 artifact zip..."
curl -L -o artifact.zip "$artifact_url"
unzip -o artifact.zip
rm artifact.zip

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
