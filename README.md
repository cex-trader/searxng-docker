# SearXNG Docker

基于 [SearXNG](https://github.com/searxng/searxng) 的 Docker 本地部署方案，支持通过 `.env` 统一配置代理。

## 快速开始

```bash
# 1. 克隆仓库
git clone git@github.com:cex-trader/searxng-docker.git
cd searxng-docker

# 2. 配置代理（可选）
cp .env.example .env
vi .env    # 填入代理地址

# 3. 启动
docker compose up -d

# 4. 访问
open http://localhost:8787
```

## 代理配置

所有代理配置集中在 `.env` 文件中，修改后重启即可生效。

```bash
cp .env.example .env
```

编辑 `.env`：

```env
# 局域网代理服务器
PROXY_SOCKS5=192.168.1.1:1080
PROXY_HTTP=192.168.1.1:8123

# 或本机代理（Clash / V2Ray 等）
PROXY_SOCKS5=host.docker.internal:7890

# 不使用代理 — 留空或注释掉
# PROXY_SOCKS5=
# PROXY_HTTP=
```

| 变量 | 说明 | 示例 |
|------|------|------|
| `PROXY_SOCKS5` | SOCKS5 代理地址（自动使用 `socks5h` 协议，DNS 走代理解析） | `192.168.1.1:1080` |
| `PROXY_HTTP` | HTTP 代理地址 | `192.168.1.1:8123` |

> **注意**：格式为 `地址:端口`，不需要加 `socks5://` 或 `http://` 前缀。

> **`host.docker.internal`**：Docker 容器访问宿主机的特殊地址。如果代理运行在本机，用它代替 `127.0.0.1`。

### 代理工作原理

容器启动时，`entrypoint.sh` 读取 `.env` 中的代理变量，通过 Python 脚本动态注入到 SearXNG 的 `settings.yml` 的 `outgoing.proxies` 配置中。SOCKS5 自动使用 `socks5h` 协议（DNS 也走代理解析）。

当两个变量都设置时，SearXNG 按顺序 failover：SOCKS5 失败则切换到 HTTP 代理。

## 常用操作

```bash
# 启动
docker compose up -d

# 停止
docker compose down

# 重启（修改 .env 或 settings.yml 后）
docker compose restart searxng

# 查看日志
docker compose logs -f searxng

# 更新镜像
docker compose pull && docker compose up -d
```

## 文件说明

```
.
├── .env.example        # 代理配置模板，复制为 .env 使用
├── .env                # 实际代理配置（git 忽略）
├── docker-compose.yml  # Docker Compose 编排
├── entrypoint.sh       # 启动脚本，从环境变量注入代理到 settings.yml
├── settings.yml        # SearXNG 基础配置（搜索引擎、语言、UI 等）
└── limiter.toml        # 速率限制配置（本地部署已关闭）
```

## 自定义配置

### 修改端口

编辑 `docker-compose.yml`，将 `8787` 改为目标端口：

```yaml
ports:
  - "9090:8080"   # 改为 9090
```

同时更新 `SEARXNG_BASE_URL`：

```yaml
environment:
  - SEARXNG_BASE_URL=http://localhost:9090/
```

### 添加/禁用搜索引擎

编辑 `settings.yml` 的 `engines` 部分：

```yaml
engines:
  - name: google
    engine: google
    shortcut: g
    disabled: false    # 改为 true 可禁用

  # 添加新引擎
  - name: brave
    engine: brave
    shortcut: br
    disabled: false
```

完整引擎列表参考：[SearXNG Engines](https://docs.searxng.org/user/configured_engines.html)

### 开启速率限制

如果部署到公网，建议开启 limiter 并配合反向代理（Nginx/Caddy）：

1. `settings.yml` 中设置 `limiter: true`
2. 反向代理需设置 `X-Forwarded-For` 头
3. 编辑 `limiter.toml` 调整限制策略

## 安全提示

- `settings.yml` 中的 `secret_key` 用于会话签名，公网部署前请重新生成：
  ```bash
  python3 -c "import secrets; print(secrets.token_hex(32))"
  ```
- `.env` 已加入 `.gitignore`，代理地址不会提交到仓库
- 本地部署已关闭 `limiter`，公网暴露前务必开启
