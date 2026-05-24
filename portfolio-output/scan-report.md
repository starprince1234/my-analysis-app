# 项目扫描报告

## 目录结构（事实）

```
my-analysis-app/
├── backend/
│   ├── app.py
│   ├── logic/
│   │   ├── stress_analyzer.py
│   │   ├── nodule_detector.py
│   │   └── stats_processor.py
│   ├── uploads/                # 已存在历史上传文件
│   ├── results/                # 已存在历史生成结果（GIF / PNG / JSON）
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   ├── index.html
│   ├── css/style.css
│   └── js/main.js
├── nginx/
│   ├── nginx.conf
│   └── Dockerfile
├── docker-compose.yml
└── portfolio-output/           # 本次生成
```

## 项目类型判断（事实）

- 类型：Web 应用 / 数据分析工具
- 形态：单页前端 + Python 后端 + Nginx 反向代理 + Docker Compose 部署
- 业务定位：传感矩阵 CSV 数据的可视化与统计分析

## 技术栈判断（事实）

来源：`backend/requirements.txt`、`backend/Dockerfile`、`nginx/Dockerfile`、`frontend/index.html`。

- 后端语言/运行时：Python 3.12（python:3.12-slim 镜像）
- Web 框架：Flask 3.1.2
- 实时通信：Flask-SocketIO 5.5.1（前端使用 socket.io-client 4.5.4 CDN）
- WSGI 服务器：Gunicorn + eventlet（`--worker-class eventlet -w 1`）
- 数据/算法：pandas、numpy、matplotlib、Pillow、scikit-learn、scikit-image
- 跨域：Flask-Cors（同时由 Nginx 设置 CORS 头）
- 反向代理 / 静态：Nginx（nginx:alpine）
- 部署：Docker + docker-compose

## 前端框架（事实）

- 未使用任何前端框架（无 package.json / 无构建工具）。
- 原生 HTML + CSS + JavaScript。
- 通过 CDN 引入 `socket.io.min.js@4.5.4`。

## 后端框架（事实）

- Flask 3.1.2 + Flask-SocketIO 5.5.1。
- HTTP 仅一个端点：`POST /api/upload`。
- 其余交互全部走 SocketIO 事件：`start_processing` / `progress_update` / `task_complete` / `error`。

## 数据库 / 存储（事实）

- 无任何数据库（未发现 SQL/ORM 代码、未发现连接配置）。
- 持久化方式：本地文件系统
  - `backend/uploads/<uuid>.csv`
  - `backend/results/<uuid>.<gif|png|json>`
- 通过 docker-compose volume 在 backend / nginx 间共享 `results` 目录。

## AI / LLM / 外部 API 调用能力（事实）

- 未发现任何 LLM / 外部 AI API 调用。
- "智能"部分来自传统 ML / CV 算法：scikit-learn 的 GaussianMixture、KMeans、StandardScaler；scikit-image 的形态学与连通域分析。

## 部署方式（事实）

- `docker-compose.yml` 定义两个服务：
  - `backend`：python:3.12-slim 镜像，命令 `gunicorn --worker-class eventlet -w 1 --bind 0.0.0.0:5000 app:app`，挂载源码与 results 目录。
  - `nginx`：nginx:alpine，监听 80，挂载 `nginx.conf` 和只读的 results 目录。
- 没有 CI/CD 配置文件（未发现 `.github/`、`.gitlab-ci.yml`、`Jenkinsfile` 等）。

## 入口文件（事实）

- 后端：`backend/app.py`（`app = Flask(__name__)`，`socketio = SocketIO(app, cors_allowed_origins="*")`）。
- 前端：`frontend/index.html`，业务逻辑在 `frontend/js/main.js`。
- 反向代理：`nginx/nginx.conf`。

## 页面与功能模块（事实）

- 单页 4 卡片：上传 / 任务选择 / 进度 / 结果。
- 三种任务类型：`stress`、`nodule`、`stats`，分别对应 `logic/` 下三个算法模块。
- 视觉主色：indigo `#3f51b5`（来自 `frontend/css/style.css`）。

## 测试 / CI / Docker / 部署配置（事实 + 待补充）

- 测试：未发现任何测试目录或测试配置（无 `tests/`、无 `pytest.ini`、无 `conftest.py`）→ {待补充}
- CI/CD：无 → {待补充}
- Docker：✅ 已有 `backend/Dockerfile`、`nginx/Dockerfile`、`docker-compose.yml`
- README：已新增根目录 `README.md`
- LICENSE：未发现 → {待补充}
- `.env.example`：已新增根目录 `.env.example`

## 敏感信息风险（高优先级，请清理）

> 以下条目仅指出位置与类别，**不输出具体值**。请按指引自行处理。

1. **后端 SECRET_KEY 配置**
   - 位置：`backend/app.py`（顶部 Flask 配置）
   - 状态：已迁移到环境变量 `SECRET_KEY`，并在 `.env.example` 中列出占位符。
   - 建议：生产环境必须使用新的长随机值，旧开发值视为已泄露，不再复用。

2. **CORS 通配符 `*`**
   - 位置：`backend/app.py` 中 `CORS_ALLOWED_ORIGINS` 默认值，`nginx/nginx.conf` 中 `Access-Control-Allow-Origin '*'`。
   - 风险：任意源站点可调用 API / 连接 WS。
   - 建议：生产环境改为白名单（仅允许你的作品集域名 + 演示域名）。

3. **未授权静态目录**
   - 位置：Nginx `/results/` alias。
   - 风险：任何人猜到/拿到 URL 即可访问历史用户的分析结果。
   - 建议：加签名 URL、登录鉴权，或在演示版本中改为按 session 隔离子目录。

4. **历史上传/结果数据**
   - 位置：`backend/uploads/`、`backend/results/`
   - 风险：仓库里如果直接 commit 这些目录，可能携带真实数据外泄。
   - 状态：已加入 `.gitignore` 和 Docker ignore 规则。
   - 建议：不要提交这两个目录；如果未来误提交，需要从 git 历史中清理。

5. **上传体积/类型限制**
   - 位置：`backend/app.py` upload 处理。
   - 状态：已添加 `.csv` 后缀白名单与 `MAX_CONTENT_LENGTH_MB` 环境变量。
   - 建议：如果公开部署，可继续补 MIME 检查、速率限制和任务队列。

> 没有发现 API Key、第三方 Token、数据库密码、个人身份信息等显式机密。

## 已知代码缺陷（事实）

- `backend/app.py` 的 `stats` 任务返回路径 bug 已修复为 `output_filename_img`。
- 当前仍缺少自动化测试与公开可用的脱敏 sample CSV。
