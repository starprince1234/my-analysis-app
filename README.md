# 多功能分析平台

多功能分析平台是一个面向传感矩阵 CSV 数据的实时分析 Web 应用。用户上传包含 96 个传感通道的 CSV 文件后，可以在浏览器中生成应力分析动图、结节检测动图，以及统计特征聚类图表和 JSON 报告。

## 目录

- [功能特性](#功能特性)
- [技术栈](#技术栈)
- [项目结构](#项目结构)
- [环境要求](#环境要求)
- [快速开始](#快速开始)
- [环境变量](#环境变量)
- [常用命令](#常用命令)
- [测试](#测试)
- [构建](#构建)
- [部署](#部署)
- [Docker 运行方式](#docker-运行方式)
- [API 文档](#api-文档)
- [数据文件格式](#数据文件格式)
- [数据库说明](#数据库说明)
- [复现检查清单](#复现检查清单)
- [常见问题](#常见问题)
- [贡献指南](#贡献指南)
- [License](#license)

## 功能特性

- CSV 上传：通过 `POST /api/upload` 上传 `.csv` 文件，后端使用 UUID 重命名，避免覆盖同名文件。
- 应力分析动图：把 `MAT_0` 到 `MAT_95` 的 96 通道数据重塑为 12 x 8 矩阵，生成 2D 热图、3D 曲面、等高线和统计信息组成的 GIF。
- 结节检测动图：使用 Gaussian Mixture、形态学闭运算和连通域分析，生成结节检测演化 GIF。
- 统计特征分析：对各传感通道做 FFT 特征提取，再用 KMeans 聚类，输出 PNG 图和 JSON 报告。
- 实时进度反馈：长任务通过 Socket.IO 推送 `progress_update`、`task_complete` 和 `error` 事件，前端实时更新进度条。

## 技术栈

- 前端：原生 HTML、CSS、JavaScript、Socket.IO Client CDN
- 后端：Python 3.12、Flask、Flask-SocketIO
- 数据分析：pandas、numpy、matplotlib、Pillow、scikit-learn、scikit-image
- 服务运行：Gunicorn、eventlet
- 部署：Docker、Docker Compose、Nginx

## 项目结构

```text
.
├── backend/                  # Flask 后端与分析逻辑
│   ├── app.py                # HTTP API 与 Socket.IO 入口
│   ├── logic/                # 三类分析算法模块
│   ├── Dockerfile            # 后端镜像构建文件
│   └── requirements.txt      # Python 依赖
├── frontend/                 # 静态前端页面
│   ├── index.html
│   ├── css/style.css
│   └── js/main.js
├── nginx/                    # Nginx 反向代理与静态资源配置
│   ├── Dockerfile
│   └── nginx.conf
├── portfolio-output/         # 项目作品集说明与扫描文档
├── .dockerignore             # Docker 构建上下文忽略规则
├── .env.example              # 环境变量模板
├── .gitignore                # Git 忽略规则
├── docker-compose.yml        # 本地 Docker Compose 编排
└── README.md                 # 项目说明
```

运行时会生成以下本地目录，它们不应提交到 GitHub：

```text
backend/uploads/              # 用户上传的 CSV 文件
backend/results/              # 生成的 GIF / PNG 结果文件
.venv/                        # 本地 Python 虚拟环境
```

## 环境要求

推荐使用 Docker 运行，可以避免本机 Python 依赖差异。

- Docker Desktop 或 Docker Engine
- Docker Compose v2
- Git

如需不使用 Docker 本地运行后端，建议环境：

- Python 3.12
- pip
- 可以提供静态文件服务的本地 HTTP 服务器或 Nginx

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/starprince1234/my-analysis-app.git
cd my-analysis-app
```

### 2. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env`，至少修改：

```env
SECRET_KEY=replace_with_a_long_random_secret
```

生产环境还应把 `CORS_ALLOWED_ORIGINS` 改为真实域名白名单。

### 3. 使用 Docker 启动

```bash
docker compose up -d --build
```

打开浏览器访问：

```text
http://localhost
```

### 4. 上传 CSV 并运行分析

CSV 至少需要包含以下列：

- `MAT_0` 到 `MAT_95`
- 如果运行结节检测，还需要 `SN`

上传成功后，页面会显示三个任务按钮：

- 生成应力分析动画
- 运行结节检测动画
- 执行统计特征分析

## 环境变量

| 变量名 | 必填 | 默认值 | 说明 |
| ------ | ---- | ------ | ---- |
| `SECRET_KEY` | 是 | 无 | Flask 密钥。生产环境必须使用长随机值，建议放入 GitHub Secrets 或部署平台环境变量。 |
| `FLASK_ENV` | 否 | `development` | Flask 运行环境。生产环境建议设置为 `production`。 |
| `FLASK_DEBUG` | 否 | `1` | Flask 调试开关。生产环境建议设置为 `0`。 |
| `UPLOAD_FOLDER` | 否 | `uploads` | 后端容器内上传文件保存目录。 |
| `RESULT_FOLDER` | 否 | `results` | 后端容器内分析结果保存目录。 |
| `MAX_CONTENT_LENGTH_MB` | 否 | `50` | 单个上传文件最大体积，单位 MB。 |
| `CORS_ALLOWED_ORIGINS` | 否 | `*` | Socket.IO 跨域来源。生产环境建议设置为逗号分隔的域名白名单。 |

`.env.example` 只包含安全占位值，不包含真实密钥。请不要提交 `.env`。

## 常用命令

```bash
docker compose up -d --build    # 构建并后台启动服务
docker compose logs -f          # 查看服务日志
docker compose down             # 停止并移除容器
```

后端本地开发命令：

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

Windows PowerShell 中如果不使用 Docker，前端需要额外用静态服务器或 Nginx 托管，并确保 `/api/` 与 `/socket.io` 能代理到 `http://localhost:5000`。

## 测试

当前项目暂未配置自动化测试。

可以在 Docker 启动后做一个最小健康检查：

```bash
curl http://localhost
```

如果需要检查上传接口，请准备一份包含 `MAT_0` 到 `MAT_95` 的 CSV，再执行：

```bash
curl -X POST http://localhost/api/upload -F "file=@sample.csv"
```

## 构建

项目没有前端构建步骤，前端文件由 Nginx 直接提供。

Docker 构建命令：

```bash
docker compose build
```

构建产物是本地 Docker 镜像，不会写入 `dist/` 或 `build/` 目录。

## 部署

当前项目暂未提供固定云平台部署流程。部署时请先配置环境变量，并按照“构建”和“启动”章节运行。

生产部署建议：

- 设置 `SECRET_KEY` 为强随机值。
- 设置 `FLASK_ENV=production` 和 `FLASK_DEBUG=0`。
- 将 `CORS_ALLOWED_ORIGINS` 收紧为实际站点域名，例如 `https://example.com`。
- 不要提交或打包 `backend/uploads/`、`backend/results/`、`.env`、`.venv/`。
- 如果使用 GitHub Actions 或云平台部署，将 `SECRET_KEY` 放入 GitHub Secrets 或部署平台环境变量。

## Docker 运行方式

启动：

```bash
docker compose up -d --build
```

查看日志：

```bash
docker compose logs -f
```

停止：

```bash
docker compose down
```

默认端口：

```text
http://localhost
```

Nginx 会处理：

- `/`：前端静态页面
- `/api/`：反向代理到 Flask 后端
- `/socket.io`：反向代理 Socket.IO
- `/results/`：读取后端生成的结果文件

## API 文档

### Base URL

Docker 本地运行时：

```text
http://localhost
```

### 上传 CSV

```bash
curl -X POST http://localhost/api/upload -F "file=@sample.csv"
```

成功响应示例：

```json
{
  "message": "File uploaded successfully",
  "filepath": "uploads/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx_sample.csv"
}
```

失败响应示例：

```json
{
  "error": "Only CSV files are supported"
}
```

### Socket.IO 事件

客户端发送：

```js
socket.emit('start_processing', {
  task: 'stress',
  filepath: 'uploads/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx_sample.csv'
})
```

可用任务：

| task | 说明 | 输出 |
| ---- | ---- | ---- |
| `stress` | 应力分析动画 | GIF |
| `nodule` | 结节检测动画 | GIF |
| `stats` | 统计特征分析 | PNG + JSON 报告 |

服务端事件：

| 事件名 | 说明 |
| ------ | ---- |
| `progress_update` | 返回 `{ progress }`，用于更新进度条。 |
| `task_complete` | 返回 `{ result_url }`，用于显示结果。 |
| `error` | 返回 `{ message }`，用于显示错误信息。 |

## 数据文件格式

CSV 文件应至少包含 96 个传感通道列：

```text
MAT_0,MAT_1,MAT_2,...,MAT_95
```

结节检测任务还要求包含时间序列列：

```text
SN
```

注意：

- 当前项目未提交真实样例 CSV。
- `backend/uploads/` 中的本地上传数据不会提交到 GitHub。
- 如果要公开样例数据，请先确认数据已脱敏，并放在单独的 `examples/` 或 `sample/` 目录。

## 数据库说明

当前项目没有使用数据库。

上传文件和分析结果保存在本地文件系统：

- 上传文件：`backend/uploads/`
- 分析结果：`backend/results/`

这两个目录属于运行数据，已加入 `.gitignore`，不要提交真实数据或生成结果。

## 复现检查清单

- [ ] 已安装 Docker 和 Docker Compose
- [ ] 已克隆仓库
- [ ] 已复制 `.env.example` 为 `.env`
- [ ] 已填写 `SECRET_KEY`
- [ ] 已运行 `docker compose up -d --build`
- [ ] 已访问 `http://localhost`
- [ ] 已准备包含 `MAT_0` 到 `MAT_95` 的 CSV
- [ ] 已完成一次上传和分析任务

## 常见问题

### 端口 80 被占用怎么办？

修改 [docker-compose.yml](docker-compose.yml) 中的端口映射，例如：

```yaml
ports:
  - "8080:80"
```

然后访问：

```text
http://localhost:8080
```

### 上传后提示缺少 `MAT_*` 列怎么办？

请确认 CSV 包含 `MAT_0` 到 `MAT_95` 共 96 列。列名需要完全匹配。

### 结节检测提示缺少 `SN` 怎么办？

结节检测会读取 `SN` 作为时间序列列。请在 CSV 中补充 `SN` 列，或改用应力分析、统计分析任务。

### 统计分析结果图片不显示怎么办？

先查看后端日志：

```bash
docker compose logs -f backend
```

再确认 `backend/results/` 已生成 PNG 文件，并且 Nginx 正常提供 `/results/` 路径。

### 生产环境可以直接使用 `CORS_ALLOWED_ORIGINS=*` 吗？

不建议。公开部署时应设置为实际站点域名白名单，并配合鉴权或签名 URL 保护 `/results/`。

## 贡献指南

这是个人项目，暂未开放完整贡献流程。如需协作，请先提交 issue 或联系维护者。

## License

当前项目暂未包含 `LICENSE` 文件。公开发布前请确认使用 MIT、Apache-2.0 或其他许可证。
