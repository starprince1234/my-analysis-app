---
title: "多功能分析平台"
slug: "multi-analysis-platform"
description: "面向传感矩阵 CSV 数据的实时分析工具，提供应力可视化、结节检测与统计聚类三类分析能力。"
type: "Web 应用 / 数据分析工具"
status: "可演示原型 (Prototype)"
role: ["全栈开发", "产品设计", "可视化与算法"]
techStack:
  - "Python 3.12"
  - "Flask 3.1"
  - "Flask-SocketIO 5.5"
  - "Gunicorn + eventlet"
  - "pandas / numpy"
  - "matplotlib / Pillow"
  - "scikit-learn"
  - "scikit-image"
  - "Vanilla HTML/CSS/JS"
  - "Socket.IO Client"
  - "Nginx"
  - "Docker Compose"
liveUrl: "{待补充}"
githubUrl: "https://github.com/starprince1234/my-analysis-app"
cover: "./assets/cover.png"
createdAt: "{待补充}"
updatedAt: "2026-05-24"
---

## 项目概览

多功能分析平台是一个面向传感器矩阵数据（12×8 = 96 通道）的轻量级 Web 分析工具。用户上传一份 CSV 文件后，可在同一界面中触发三类分析任务，并通过 WebSocket 实时看到处理进度，最终在浏览器内查看动态可视化结果。

平台目标是把"上传 → 处理 → 可视化"这一典型科学数据工作流，从本地脚本搬到一个可分享、可演示的 Web 端，降低非技术用户的使用门槛。

## 项目背景

实验或工业场景下采集到的多通道传感数据，通常以 CSV 形式落地，分析过程依赖 Python 脚本和 Jupyter，结果分散、难以分享。本项目把常见的三类分析（应力演化、结节检测、统计聚类）抽成统一的 Web 服务，让任何拿到链接的人都能上传数据、看结果，而不需要本地 Python 环境。

## 目标用户

- 需要快速查看传感矩阵随时间演化趋势的研究者或工程师
- 希望把分析流程演示给非技术同事/客户的开发者
- 教学场景中需要展示数据可视化与轻量算法的讲师

## 核心功能

1. **CSV 上传与校验**：浏览器端选择文件，后端使用 UUID 重命名落盘，避免命名冲突。
2. **应力分析动图**：将 96 列重塑为 12×8 矩阵，逐帧渲染 2D 热力图、3D 曲面、等高线和统计面板，输出 GIF。
3. **结节检测动图**：使用高斯混合模型分离前景，叠加形态学闭运算，跟踪连通域的面积、圆度和强度变化。
4. **统计特征分析**：对每列时间序列做 FFT，取平均幅值后用 KMeans 进行 3 类聚类，输出散点图与 JSON 报告。
5. **实时进度反馈**：所有任务通过 Socket.IO 推送 `progress_update`、`task_complete`、`error` 事件，前端即时刷新进度条与结果。

## 技术栈

- **后端**：Flask 3.1 + Flask-SocketIO 5.5，部署使用 Gunicorn + eventlet 单进程异步模型
- **算法/可视化**：pandas、numpy、matplotlib、Pillow、scikit-learn、scikit-image
- **前端**：原生 HTML/CSS/JavaScript + Socket.IO 客户端 4.5.4（CDN）
- **基础设施**：Nginx 反向代理（`/api/`、`/socket.io`、`/results/` 静态资源）
- **部署**：Docker + docker-compose，两服务（backend、nginx）

## 技术架构

```
浏览器  ──HTTP/WS──▶  Nginx (80)  ──▶  Flask + SocketIO (5000, gunicorn-eventlet)
                              │              │
                              │              ├─ uploads/   (UUID 命名 CSV，运行数据)
                              ▼              ├─ results/   (GIF / PNG，运行数据)
                          /results/   ◀──── 静态目录挂载（read-only）
```

- 客户端发起 `POST /api/upload` 上传 CSV，服务器返回 `filepath`。
- 客户端通过 Socket.IO `start_processing` 事件指定任务类型（`stress` / `nodule` / `stats`）。
- 后端在协程中执行算法，每完成一个阶段 emit 一次 `progress_update`。
- 任务结束 emit `task_complete`，前端拼接 `result_url` 显示动图或报告。

## 我的职责

- 项目从 0 到 1 的端到端实现：架构选型、后端服务、前端交互、部署脚本
- 数据处理与可视化逻辑：把原始一维 CSV 重塑为时空矩阵，并设计三类分析的呈现方式
- WebSocket 进度通道设计与异常分支处理
- Docker 化与 Nginx 反向代理配置

## 项目亮点

- **统一的实时通道**：所有耗时任务都走同一套 Socket.IO 进度协议，前端只需要一份处理逻辑。
- **算法 × 可视化耦合度低**：三个 `logic/*.py` 模块独立可测，新增一种分析只需要补一个 task type 与一份算法函数。
- **零数据库的轻量部署**：用文件系统 + UUID 命名作为最简持久层，部署只需一条 `docker compose up`。
- **多视图同框**：应力分析在一帧内同时呈现 2D/3D/等高线/统计指标，便于在演示中一眼看出现象。

## 挑战与解决方案

- **WebSocket 与多 Worker 不兼容**：gunicorn 默认 prefork 多 worker 时 Socket.IO 房间会跨进程错乱。最终选择 `--worker-class eventlet -w 1` 单 worker + 协程模型，牺牲水平扩展换取实现简单。
- **matplotlib 在子进程中渲染卡顿**：通过显式使用 `Agg` 后端、控制 figure 数量与及时 `plt.close()`，避免内存泄漏。
- **CSV 列数与矩阵形状强耦合**：约束输入必须包含 `MAT_0..MAT_95` 96 列，并在管线开头显式校验，缺列直接 emit `error` 事件中断。
- **静态结果跨容器共享**：把 `backend/results/` 同时挂到 backend（读写）和 nginx（只读），避免再起一个对象存储。

## 我学到了什么

- 单 worker + 协程是 WebSocket 实时应用最稳的最小可行架构
- 把"算法"与"渲染/IO"切开，能让同一份分析逻辑既可在 CLI 跑也能在 Web 跑
- 即便是个人项目，把上传/结果路径用 UUID 隔离，比保留原文件名要省心得多

## 后续计划

- 增加用户系统与历史任务列表（目前任何人都可访问 `/results/`）
- 补 LICENSE、最小回归测试
- 收紧生产环境 CORS 来源与结果目录访问权限
- 输出 Live Demo 与一段 30s 演示视频用于作品集

## 项目链接

- Live Demo：{待补充}
- GitHub：https://github.com/starprince1234/my-analysis-app
- 演示视频：{待补充}
