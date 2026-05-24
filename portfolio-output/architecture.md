# 技术架构

## 项目结构

```
my-analysis-app/
├── backend/
│   ├── app.py                  # Flask + SocketIO 入口，REST + WS 路由
│   ├── logic/
│   │   ├── stress_analyzer.py  # 应力分析 GIF 生成
│   │   ├── nodule_detector.py  # 结节检测 GIF 生成
│   │   └── stats_processor.py  # FFT + KMeans 统计分析
│   ├── uploads/                # UUID 命名的上传 CSV（运行数据，不提交）
│   ├── results/                # 生成的 GIF / PNG（运行数据，不提交）
│   ├── requirements.txt
│   └── Dockerfile              # python:3.12-slim 基础镜像
├── frontend/
│   ├── index.html              # 4 卡片布局：上传 / 任务 / 进度 / 结果
│   ├── css/style.css           # 主题色 #3f51b5
│   └── js/main.js              # Socket.IO 客户端 + fetch 上传
├── nginx/
│   ├── nginx.conf              # 反向代理 + 静态目录
│   └── Dockerfile              # nginx:alpine
├── .env.example                # 环境变量模板
├── .gitignore                  # Git 忽略规则
├── README.md                   # 复现运行说明
└── docker-compose.yml          # backend + nginx 两服务
```

## 前端架构

- 单页静态站点，使用原生 HTML/CSS/JS，未引入任何框架。
- Socket.IO 客户端通过 CDN 引入（4.5.4）。
- 文件上传通过 `fetch('/api/upload', { method: 'POST', body: FormData })` 完成。
- 任务启动通过 `socket.emit('start_processing', { filepath, task })`。
- 统一监听三类事件：`progress_update`、`task_complete`、`error`，对应 UI 卡片状态切换。
- 视觉风格：indigo 主色 + 卡片化布局，强调"上传—任务—进度—结果"四步线性流程。

## 后端架构

- Flask 3.1 作为 HTTP 入口，仅暴露一个 `POST /api/upload`。
- Flask-SocketIO 提供 WebSocket 通道，承载所有耗时任务。
- 运行时：Gunicorn `--worker-class eventlet -w 1`，单 worker + 协程，避免多进程下 WS 房间错乱。
- 任务分发：`start_processing` 事件根据 `task` 进入 `stress` / `nodule` / `stats` 三个分支。
- 进度回调：算法函数接收一个 `progress_callback`，由 SocketIO emit 包装，让算法层无需感知 WS 细节。
- 敏感配置：`SECRET_KEY`、上传目录、结果目录、上传大小限制和 Socket.IO CORS 来源通过环境变量配置。

## 数据流

```
用户选择 CSV
   │
   ▼
POST /api/upload  ──► UUID 命名 → backend/uploads/<uuid>_<filename>.csv → 返回 filepath
   │
   ▼
emit('start_processing', { filepath, task })
   │
   ▼
后端分发：
   stress  → stress_analyzer.create_stress_animation()
   nodule  → nodule_detector.create_nodule_evolution_gif()
   stats   → stats_processor.run_statistical_analysis()
   │
   ▼
算法过程中多次 emit('progress_update', { progress })
   │
   ▼
完成后写入 backend/results/<uuid>.<gif|png>
   │
   ▼
emit('task_complete', { result_url, ... })
   │
   ▼
前端用 result_url 渲染图像 / 报告
```

## API 设计

### REST

| Method | Path           | 说明                              |
|--------|----------------|-----------------------------------|
| POST   | `/api/upload`  | 上传 CSV，返回 `{ filepath }`      |

### WebSocket 事件

| 方向       | 事件               | Payload                                              |
|------------|--------------------|------------------------------------------------------|
| C → S      | `start_processing` | `{ filepath, task: 'stress'\|'nodule'\|'stats' }`     |
| S → C      | `progress_update`  | `{ progress: number }`                                |
| S → C      | `task_complete`    | `{ result_url, ... }`                                |
| S → C      | `error`            | `{ message }`                                        |

### 静态资源

- `/results/<filename>` 由 Nginx 直接从挂载目录提供，不经过 Flask。

## 数据库 / 存储

- 当前版本未使用任何数据库。
- 上传文件以 `uploads/<uuid>_<filename>.csv` 形式持久化，结果以 `results/<uuid>.<gif|png>` 形式持久化。
- 没有任务表、用户表、历史记录表。
- 结果目录通过 Docker 卷挂载在 backend（读写）与 nginx（只读）之间共享。

## 部署方式

- 开发：`docker compose up`，backend 代码以卷挂载方式实时同步。
- 端口：Nginx 暴露 `80:80`，backend 在容器内监听 `5000`，不直接对外暴露。
- Nginx 配置要点：
  - `/api/` → `http://backend:5000`
  - `/socket.io/` → 加 `Upgrade` / `Connection: upgrade` 头转发
  - `/results/` → alias 到 `/app/results/`，由 Nginx 直接送出
  - CORS 设置为 `Access-Control-Allow-Origin *`（演示用，生产需收紧）

## 关键技术实现

- **CSV → 12×8 矩阵**：约定 96 列 `MAT_0..MAT_95`，按时间步迭代，每步 `np.array(...).reshape(12, 8)`。
- **多视图同框渲染**：matplotlib `GridSpec` 把单帧拆为 2D 热力图、3D 曲面、等高线、统计文本四个子图，再用 PIL 合成 50 帧 GIF。
- **结节检测**：`GaussianMixture(n_components=2)` 分离前景，`closing(mask, disk(2))` 平滑边缘，`regionprops` 提取面积/圆度。
- **统计分析**：96 列各做 FFT，取平均幅值组成特征向量，`StandardScaler` 归一化后 `KMeans(n_clusters=3)` 聚类。
- **进度回调**：算法函数签名统一为 `fn(input_path, output_path, progress_cb)`，把 WS 细节挡在 app.py 一层。

## 可优化点

- **横向扩展**：当前 `-w 1` 单 worker 是 WS 实时性的折中，量级上来后需要引入 Redis 作为 SocketIO message_queue 才能多 worker。
- **任务持久化**：刷新页面或断线后无法恢复任务状态，需要引入任务表 + 任务 ID。
- **静态目录权限**：`/results/` 当前任何人可访问，需要加签名 URL 或鉴权。
- **配置外置**：`SECRET_KEY`、Socket.IO CORS 来源、上传大小限制等已迁移到环境变量；Nginx CORS 头仍建议生产环境收紧。
- **观测性缺失**：无结构化日志、无指标，长任务出错只能看 stdout。
- **测试缺失**：当前没有自动化测试，建议补一份脱敏 CSV 作为 fixture，覆盖上传和三类分析的 happy path。
