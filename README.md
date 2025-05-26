# AutoBuildOpenWrtDockerImage

本项目基于 GitHub Actions 自动构建适用于 NAS/服务器的 OpenWrt x86_64 Docker 镜像，集成常用插件与中文界面，支持一键部署与配置持久化。

---

## 项目亮点

- **自动化构建**：每月自动拉取 OpenWrt 最新稳定源码并构建镜像
- **插件丰富**：内置 Passwall2、DDNS、UPnP 等常用插件
- **中文支持**：集成 Luci 中文界面
- **配置灵活**：支持自定义 LAN IP、PPPoE 等参数
- **版本可追溯**：镜像文件带有日期版本号，便于回滚
- **易于部署**：支持 Docker Compose，配置持久化简单

---

## 快速开始

### 1. 获取镜像

前往 [Actions 页面](https://github.com/mand-byte/AutoBuildOpenWrtDockerImage/actions) 下载最新 `openwrt-nas-docker-image-YYYYMMDD.tar`，或运行自动化脚本：

```bash
# 需安装 jq、curl、unzip
./update_openwrt.sh [YYYYMMDD]  # 不填日期则下载最新
```

### 2. 导入 Docker 镜像

```bash
docker load -i openwrt-nas-docker-image-YYYYMMDD.tar
```

### 3. 持久化配置

首次启动后，将容器内 `/etc/config` 拷贝到宿主机，后续挂载实现配置持久化：

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

## 自动化流程

- 每月1日自动构建，可手动触发
- 步骤涵盖源码拉取、插件集成、定制配置、镜像打包与上传
- 构建产物带日期版本号，便于历史回溯

---

## 常见问题解答

- **容器内内核是 OpenWrt 吗？**  
  不是，容器实际运行宿主机 Linux 内核，OpenWrt 仅为用户空间环境。

- **如何回滚历史版本？**  
  下载指定日期 tar 包，`docker load` 后用 compose 启动即可。

---

## 免责声明

本项目仅供学习和研究，使用请遵守相关法律法规。

---

## 致谢

- [OpenWrt](https://github.com/openwrt/openwrt)
- [Passwall2](https://github.com/xiaorouji/openwrt-passwall2)
