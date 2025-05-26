# Build OpenWrt x86_64 Docker Image (for NAS)

本项目通过 GitHub Actions 自动构建适用于 NAS 的 OpenWrt x86_64 Docker 镜像，集成常用插件（如 Passwall2、DDNS、UPnP）和中文界面，每月自动构建一次，并可通过 Docker Compose 部署在你的服务器或 NAS 上。

---

## 功能特性

- 自动拉取 OpenWrt 最新稳定分支源码
- 集成 Passwall2、DDNS、UPnP 等常用插件
- 集成 Luci 中文翻译
- 支持自定义 LAN IP、PPPoE 拨号参数
- 每月自动构建，产物带有年月日版本号，方便回滚
- 产物为可直接运行的 Docker 镜像 tar 包

---

## 使用方法

### 1. 下载最新镜像

你可以在 [GitHub Actions](https://github.com/mand-byte/AutoBuildOpenWrtDockerImage/actions) 页面下载最新的 `openwrt-nas-docker-image-YYYYMMDD.tar`，或使用自动化脚本一键下载并部署：

```bash
# 依赖 jq、curl、unzip
./update_openwrt.sh [YYYYMMDD]  # 不指定日期则下载最新
```

### 2. 导入镜像

```bash
docker load -i openwrt-nas-docker-image-YYYYMMDD.tar
```

### 3. 持久化配置目录

首次运行后可将容器内 `/etc/config` 拷贝到宿主机，后续挂载以持久化配置：

```bash
docker cp openwrt:/etc/config /your/path/openwrt-config
```

### 4. Docker Compose 示例

```yaml
version: '3.8'
services:
  openwrt:
    image: openwrt-nas:latest
    container_name: openwrt
    privileged: true
    networks:
      openwrt_lan:
        ipv4_address: 192.168.1.1
    devices:
      - eth1   # 直通WAN口
    volumes:
      - /your/path/openwrt-config:/etc/config
    restart: unless-stopped

networks:
  openwrt_lan:
    driver: ipvlan
    driver_opts:
      parent: eth0
    ipam:
      config:
        - subnet: 192.168.1.0/24
          gateway: 192.168.1.1
```

---

## 工作流说明

- 每月1日自动构建一次，也可手动触发
- 构建产物包含年月日版本号，方便历史版本回滚
- 主要步骤包括源码拉取、插件集成、配置定制、Docker 镜像打包与上传

---

## 常见问题

- **Q: 容器内显示的内核是 OpenWrt 吗？**  
  A: 不是，容器内实际运行的是宿主机的 Linux 内核，OpenWrt 仅为用户空间环境。

- **Q: 如何回滚到历史版本？**  
  A: 下载对应日期的 tar 包，`docker load` 后用 compose 启动即可。
---

## 免责声明

本项目仅供学习和研究使用，使用过程中请遵守相关法律法规。

---

## 致谢

- [OpenWrt 官方项目](https://github.com/openwrt/openwrt)
- [Passwall2](https://github.com/xiaorouji/openwrt-passwall2)
