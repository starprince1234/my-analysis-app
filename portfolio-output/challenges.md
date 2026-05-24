# 挑战与复盘

## 开发过程中遇到的问题

- WebSocket 在多 worker 下房间错乱、消息丢失。
- matplotlib 在长任务中频繁创建 figure，导致内存增长与 GIF 渲染变慢。
- 算法函数和 SocketIO 直接耦合，会让 logic 模块难以单独测试或在 CLI 复用。
- 静态结果（GIF/PNG/JSON）需要在 backend 与 nginx 容器之间共享。
- 上传同名文件会互相覆盖，结果目录也会被污染。

## 技术挑战

- **实时通道架构选型**：在"轮询 + 状态查询" 与 "WebSocket 推送"之间选择，最终选 WS 是为了让进度文案与百分比都能即时更新。
- **协程 vs 多进程**：Flask-SocketIO 在 prefork 多 worker 下需要额外的 message_queue（如 Redis）才能正常广播。为了让项目"一条命令跑起来"，最终选 `eventlet` + 单 worker。
- **算法层与 IO 层解耦**：把"如何上报进度"做成回调，让 `logic/*.py` 不依赖 Flask、SocketIO 或具体路径，纯函数化便于测试。
- **可视化性能**：matplotlib 渲染单帧已经不便宜，再做 50 帧 GIF 需要严格控制 figure 生命周期。

## 产品挑战

- **目标用户模糊**：从"我自己分析数据"到"演示给别人看"是两套体验。最终把页面做成线性四步流程，假设用户首次接触。
- **任务种类抽象**：三种分析的输入相同、输出形式不同，需要一套"通用进度 + 多形态结果"的协议。
- **失败可观测性**：长任务中途出错时，用户最怕看到一个静止的进度条。所以错误必须是显式事件，而不是超时。

## 设计挑战

- **单页四卡片**：避免多页面跳转打断"上传-处理-结果"的心流。
- **配色克制**：indigo 主色 + 中性灰背景，把视觉重量留给图表本身。
- **进度文案**：每一步都给一句人话，而不是单独一个百分数，让等待过程不那么焦虑。

## 我是如何解决的

- **WS 单 worker**：`gunicorn --worker-class eventlet -w 1 --bind 0.0.0.0:5000`，明确接受不水平扩展的代价。
- **matplotlib 内存治理**：强制 `Agg` 后端、复用 figure、每帧渲染后 `plt.close()`、必要时把每帧先存成 PNG，再用 PIL 合成 GIF。
- **回调式进度**：算法函数签名 `fn(input_path, output_path, progress_cb)`，`app.py` 一层把 `progress_cb` 包装成 emit。
- **共享卷**：docker-compose 里把 `backend/results` 挂到 backend 与 nginx，nginx 直接以 `alias /app/results/` 提供静态文件，不再经过 Flask。
- **UUID 命名**：上传 / 结果文件全部走 `uuid4()`，彻底躲开命名冲突。

## 如果重构

- 引入 Redis 作为 SocketIO `message_queue`，解锁多 worker。
- 把任务状态写入轻量 SQLite（或 Postgres），支持页面刷新后恢复进度、按链接重看历史结果。
- 把 `logic/*.py` 抽成独立 Python 包，提供 CLI 入口，让算法可以脱离 Web 单跑。
- 用 Pydantic / dataclass 定义任务请求与响应的 schema，避免裸 dict 出现 typo（例如当前 `stats` 分支的 `output_filename` bug）。
- 前端用 Vite + 任意框架（React/Vue/Svelte 都行）做组件化，方便加历史列表、参数面板。
- 把可视化产物升级为可交互的 plotly / deck.gl，让用户能在浏览器里旋转 3D 视图、缩放热力图。
- 配置外置：`SECRET_KEY`、CORS allowlist、上传大小、簇数等通过 `.env` 注入。

## 学到的东西

- 当实时性比扩展性更重要时，单 worker + 协程是最稳的"够用方案"。
- 把"算法"和"通信"从一开始就解耦，可以省掉后期一大堆改造工作。
- 对于演示型项目，UX 的可预测性（有进度、能看到错误）比功能多更重要。
- 文件系统 + UUID 命名，作为最简持久层在原型阶段几乎无可挑剔。
- 一眼能看懂的可视化，比一份精确的数字报告更能说服观众。
