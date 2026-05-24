# 待补充清单

> 以下条目是当前作品集中**事实层无法确认、需要你手动补充**的内容。
> 已尽量按"上线优先级"排序：上面的条目影响作品集是否能被外人看懂，下面的偏锦上添花。

## 一、上线必备（建议优先补齐）

### 1. 项目截图
- 位置：`portfolio-output/screenshots/`
- 建议数量：4–6 张，覆盖以下场景：
  - 首屏（4 卡片整体布局）
  - CSV 上传成功状态
  - 进度条 + 阶段文案进行中
  - 应力分析 GIF 结果页
  - 结节检测 GIF 结果页
  - 统计聚类散点图 + JSON 报告
- 命名建议：`01-home.png`、`02-upload-success.png`、`03-progress.png`、`04-stress-result.gif`、`05-nodule-result.gif`、`06-stats-result.png`
- 用途：作品集页 `screenshots[]` 字段、`index.md` 的"项目预览"区块。

### 2. 演示视频
- 位置：`portfolio-output/assets/demo.mp4`（或 YouTube / B 站链接）
- 建议长度：30–60 秒
- 建议内容：上传 CSV → 选任务 → 看进度 → 看结果，一镜到底，不需要解说。
- 用途：作品集页"项目演示"区块；展厅二维码扫码后的播放素材。

### 3. Live Demo 链接
- 当前 `summary.json` / `index.md` 中：`liveUrl: "{待补充}"`
- 选项：
  - 自建：用一台 VPS / 家用服务器 + 域名跑 `docker compose up -d`
  - 托管：Render / Fly.io / Railway 等可跑 Docker Compose 的平台
- 注意：上线前**必须**先完成下方"二、安全清理"内全部条目。

### 4. GitHub 仓库链接
- 当前 `summary.json` / `index.md` 中：`githubUrl: "{待补充}"`
- 推送前需要：
  - 在仓库根目录加 `.gitignore`，排除 `backend/uploads/`、`backend/results/`、`__pycache__/`、`.env`
  - 如果历史 commit 已经包含真实数据或密钥，需要 `git filter-repo` 或重建历史

### 5. 项目封面图
- 位置：`portfolio-output/assets/cover.png`（`summary.json` 中已写死路径）
- 建议尺寸：16:9 或 3:2，宽度 ≥ 1600px
- 内容建议：选一张视觉冲击力最强的结果（推荐应力分析 GIF 截帧或 3D 曲面）+ 项目名 + 一句副标题。
- 用途：作品集列表页缩略图、社交分享卡片。

## 二、安全清理（上线前必做）

> 详见 `scan-report.md` "敏感信息风险" 一节，这里只做 checklist。

- [x] 把 `backend/app.py` 的硬编码 `SECRET_KEY` 改为读取环境变量，并把旧开发值视为已泄露，不再复用。
- [ ] 收紧 CORS：`backend/app.py` 的 `cors_allowed_origins` 与 `nginx/nginx.conf` 的 `Access-Control-Allow-Origin` 改为白名单。
- [ ] `/results/` 目录加签名 URL 或登录鉴权，至少加一道 referer 校验。
- [x] 给上传接口加 `MAX_CONTENT_LENGTH` 与后缀白名单。
- [x] 修复 `app.py` `stats` 分支 `output_filename` → `output_filename_img` 的 bug。

## 三、文档与工程化

### 6. README
- 已新增根目录 `README.md`，覆盖本地运行、Docker 运行、环境变量、API、部署和复现清单。
- 建议章节：项目简介 / 截图或 GIF / 在线演示 / 本地运行 / 目录结构 / 技术栈 / 截图致谢 / License。
- 可以基于 `portfolio-output/index.md` 改写，去掉个人化叙述、加上"如何在本地跑起来"。

### 7. 部署文档
- 建议位置：仓库根目录 `DEPLOY.md`，或作为 README 的一个章节。
- 至少覆盖：环境要求、`docker compose up` 一条命令、端口、卷挂载说明、生产环境如何换 SECRET_KEY / CORS。

### 8. 环境变量示例 `.env.example`
- 建议位置：仓库根目录。
- 已新增 `.env.example`，列出 `SECRET_KEY`、`CORS_ALLOWED_ORIGINS`、`MAX_CONTENT_LENGTH_MB` 等占位符。
- 已同步在 `docker-compose.yml` 里用 `env_file: .env`。

### 9. LICENSE
- 当前缺失。
- 建议：MIT（最宽松、对个人作品集友好）或 Apache-2.0（带专利条款，更稳）。
- 用途：让其他人放心 fork、放心引用，也是开源履历的标配。

### 10. 安装说明 / 使用说明
- 与 README 部分重叠，但可单独作为面试或评审时的引导材料。
- 可包括：示例 CSV 文件（脱敏后的 `sample.csv`，能让别人 5 秒内跑通流程）。

## 四、项目品牌

### 11. 项目 Logo
- 当前未发现自定义 Logo / favicon。
- 建议：一个简笔图标（比如以 12×8 网格 + 一个高亮点为意象），用于 favicon、社交分享、展厅物料。

### 12. 项目截图致谢 / 截图来源
- 如果作品集中使用了任何外部素材（字体、图标、配色参考），列出出处。

## 五、运营层（可选）

### 13. 用户反馈 / 使用证言
- 如果给同学、老师、AdventureX 评委演示过，可以收 1–2 句引用。
- 即便是"它把以前要写脚本才能看的东西变成 5 秒就能看的"也很有说服力。

### 14. 项目数据 / 使用情况
- 例如：累计处理过多少份 CSV、生成过多少帧 GIF、平均一次任务多少秒。
- 没有埋点也无所谓，可以人工估算或现场跑一次记录。

### 15. 关键时间节点（`createdAt`）
- 当前 `summary.json` 中 `createdAt: "{待补充}"`。
- 建议补上：项目第一次跑通的日期。可以用 git 第一次 commit 的时间，或自己记忆中的开始日期。

## 六、长期演进（不影响本次上线）

- 引入 Redis 作为 SocketIO `message_queue`，支持多 worker。
- 引入 SQLite / Postgres 持久化任务状态，支持刷新恢复 + 历史回看。
- 把 `logic/*.py` 抽成独立 Python 包 + CLI 入口。
- 加自动化测试（pytest + 一份 sample CSV 覆盖三种 task 的 happy path）。
- 加 CI（GitHub Actions：lint + test + 可选自动构建镜像）。
- 用 Vite + 任意框架重写前端，加历史列表 / 参数面板。
