# 多功能分析平台 Flutter 跨平台客户端

这是 `my-analysis-app` 的 Flutter 跨平台客户端，用于上传传感矩阵 CSV 文件，并连接后端执行应力分析、结节检测和统计特征分析任务。客户端通过 HTTP 上传文件，通过 Socket.IO 接收任务进度和分析结果，支持 Android、iOS、Web、Windows、macOS 和 Linux 等 Flutter 目标平台。

后端代码位于同一 GitHub 仓库的 `main` 分支。本分支聚焦跨平台 Flutter 客户端。

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
- [API 文档](#api-文档)
- [数据文件格式](#数据文件格式)
- [数据库说明](#数据库说明)
- [复现检查清单](#复现检查清单)
- [常见问题](#常见问题)
- [贡献指南](#贡献指南)
- [License](#license)

## 功能特性

- CSV 文件选择与上传：使用系统文件选择器选择 `.csv` 文件，并上传到 Flask 后端的 `/api/upload` 接口。
- 多任务分析入口：支持 `stress`、`nodule`、`stats` 三类任务，对应应力分析动画、结节检测动画和统计特征分析。
- 实时进度展示：通过 Socket.IO 监听 `progress_update`、`task_complete` 和 `error` 事件，实时刷新进度和结果。
- 结果展示：支持展示后端返回的 GIF、PNG 和统计报告文本。
- 跨平台 DPI / 缩放信息：通过 Flutter MethodChannel 调用平台原生代码，获取 Android、iOS、Windows 等平台的缩放或 DPI 信息。
- 可缩放界面：主页面使用 `InteractiveViewer`，支持用户缩放和平移分析操作界面。

## 技术栈

- 客户端：Flutter、Dart
- 状态管理：provider
- 网络请求：http
- 实时通信：socket_io_client
- 文件选择：file_picker
- 原生能力：Flutter MethodChannel
- 后端依赖：同仓库 `main` 分支中的 Flask / Flask-SocketIO 服务

## 项目结构

```text
.
├── android/                 # Android 平台工程
├── ios/                     # iOS 平台工程
├── lib/                     # Flutter/Dart 源码
│   ├── app_state.dart       # 应用状态、后端通信、Socket.IO 事件处理
│   └── main.dart            # Flutter 应用入口和页面 UI
├── linux/                   # Linux 桌面平台工程
├── macos/                   # macOS 平台工程
├── test/                    # Flutter widget 测试
├── web/                     # Web 平台资源
├── windows/                 # Windows 桌面平台工程
├── .env.example             # 后端地址配置示例
├── .gitignore               # Git 忽略规则
├── analysis_options.yaml    # Dart/Flutter 静态分析规则
├── pubspec.yaml             # Flutter 依赖与项目配置
├── pubspec.lock             # Dart 依赖锁定文件
└── README.md                # 项目说明
```

以下目录和文件是本地生成内容，不应提交到 GitHub：

```text
.dart_tool/
build/
**/flutter/ephemeral/
local.properties
android/local.properties
```

## 环境要求

- Flutter SDK：建议使用 stable 渠道，项目 `.metadata` 创建版本为 Flutter `3.35.2` 对应的模板版本。
- Dart SDK：`pubspec.yaml` 要求 `^3.9.2`。
- Git
- 至少一个 Flutter 运行目标，例如 Chrome、Android 模拟器、Windows 桌面、iOS 模拟器等。
- 后端服务：同仓库 `main` 分支的 Flask / Socket.IO 后端，默认监听 `http://localhost:5000`。

查看本机 Flutter 环境：

```bash
flutter doctor
flutter devices
```

## 快速开始

### 1. 克隆跨平台客户端分支

```bash
git clone -b 跨平台 https://github.com/starprince1234/my-analysis-app.git
cd my-analysis-app
```

如果还需要本地启动后端，请另行克隆或切换同仓库 `main` 分支，并按 `main` 分支 README 启动 Flask 后端。

### 2. 安装 Flutter 依赖

```bash
flutter pub get
```

### 3. 配置后端地址

本项目使用 Flutter 编译期变量 `BACKEND_URL` 配置后端地址。默认值是：

```text
http://localhost:5000
```

`.env.example` 用于记录需要配置的变量名。Flutter 不会自动读取 `.env` 文件，运行时请通过 `--dart-define` 传入：

```bash
flutter run --dart-define=BACKEND_URL=http://localhost:5000
```

如果后端运行在其他机器或端口，例如局域网服务器：

```bash
flutter run --dart-define=BACKEND_URL=http://192.168.1.10:5000
```

### 4. 启动后端服务

后端位于同仓库 `main` 分支。使用 Docker 时，后端 README 中的完整 Web 应用通常通过 Nginx 暴露在 `http://localhost`，而 Flask 容器内部监听 `5000`。

如果只运行 Flask 后端本身，请确保客户端可以访问：

```text
http://localhost:5000/api/upload
http://localhost:5000/socket.io
```

### 5. 启动客户端

Web：

```bash
flutter run -d chrome --dart-define=BACKEND_URL=http://localhost:5000
```

Windows：

```bash
flutter run -d windows --dart-define=BACKEND_URL=http://localhost:5000
```

Android：

```bash
flutter run -d android --dart-define=BACKEND_URL=http://10.0.2.2:5000
```

Android 模拟器访问宿主机服务时通常需要使用 `10.0.2.2`，真机需要使用电脑在同一局域网中的 IP 地址。

## 环境变量

| 变量名 | 必填 | 默认值 | 说明 |
| ------ | ---- | ------ | ---- |
| `BACKEND_URL` | 否 | `http://localhost:5000` | Flask / Socket.IO 后端地址。部署或 CI 构建时建议作为环境变量或 GitHub Secrets 注入，不要在源码中硬编码真实内网地址、公网密钥或账号信息。 |

本项目当前没有读取真实 `.env` 文件，也没有需要提交的密钥。`.env.example` 只记录变量名和安全示例值。

## 常用命令

```bash
flutter pub get                         # 安装依赖
flutter analyze                         # 静态分析
flutter test                            # 运行测试
flutter run -d chrome                   # 启动 Web 调试
flutter run -d windows                  # 启动 Windows 桌面调试
flutter run -d android                  # 启动 Android 调试
flutter clean                           # 清理 Flutter 构建缓存
```

带后端地址运行：

```bash
flutter run -d chrome --dart-define=BACKEND_URL=http://localhost:5000
```

## 测试

运行自动化测试：

```bash
flutter test
```

运行静态分析：

```bash
flutter analyze
```

当前测试覆盖首页是否能正常渲染上传区、系统信息区和初始状态文案。测试不会连接真实后端。

## 构建

Web 构建：

```bash
flutter build web --dart-define=BACKEND_URL=https://your-backend.example.com
```

Android APK 构建：

```bash
flutter build apk --dart-define=BACKEND_URL=https://your-backend.example.com
```

Windows 构建：

```bash
flutter build windows --dart-define=BACKEND_URL=https://your-backend.example.com
```

构建产物通常位于 `build/` 目录。`build/` 是本地生成目录，不应提交到 GitHub。

## 部署

当前分支没有固定云平台部署流程。部署时请先确认：

- 后端服务已经部署，并且客户端可以访问 `/api/upload` 和 `/socket.io`。
- 使用 `--dart-define=BACKEND_URL=...` 注入生产后端地址。
- 不要把真实内网地址、密钥、证书或本地配置写入源码。

Web 部署的一般流程：

```bash
flutter build web --dart-define=BACKEND_URL=https://your-backend.example.com
```

然后将 `build/web/` 部署到静态托管平台或 Nginx。

如果使用 GitHub Actions 构建，建议将生产后端地址配置为 GitHub Secrets，例如：

```text
BACKEND_URL
```

## API 文档

### Base URL

默认本地后端：

```text
http://localhost:5000
```

### 上传 CSV

```bash
curl -X POST http://localhost:5000/api/upload -F "file=@sample.csv"
```

成功响应示例：

```json
{
  "message": "File uploaded successfully",
  "filepath": "uploads/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx_sample.csv"
}
```

客户端也兼容包含 `data.filepath` 的响应结构。

### Socket.IO 任务事件

客户端发送：

```json
{
  "task": "stress",
  "filepath": "uploads/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx_sample.csv"
}
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
| `progress_update` | 返回 `{ "progress": 0-100 }`，用于更新进度条。 |
| `task_complete` | 返回 `{ "result_url": ... }`，用于展示图片或报告。 |
| `error` | 返回 `{ "message": "..." }`，用于展示错误。 |

## 数据文件格式

CSV 文件至少需要包含传感矩阵列：

```text
MAT_0,MAT_1,MAT_2,...,MAT_95
```

结节检测任务还需要：

```text
SN
```

注意：

- 当前分支未提交真实样例 CSV。
- 不要提交真实用户数据、上传文件、分析结果或数据库 dump。
- 如果未来添加样例数据，请先确认数据已脱敏，并放入 `examples/` 或 `sample/` 目录。

## 数据库说明

当前 Flutter 客户端不直接连接数据库。

上传文件、结果文件和数据持久化由后端负责。请参考同仓库 `main` 分支 README 中的后端说明。

## 复现检查清单

- [ ] 已安装 Flutter SDK
- [ ] 已安装 Git
- [ ] 已克隆 `跨平台` 分支
- [ ] 已运行 `flutter pub get`
- [ ] 已启动同仓库 `main` 分支后端
- [ ] 已确认客户端可访问 `BACKEND_URL`
- [ ] 已运行 `flutter analyze`
- [ ] 已运行 `flutter test`
- [ ] 已通过 `flutter run` 启动客户端
- [ ] 已上传包含 `MAT_0` 到 `MAT_95` 的 CSV 并完成一次分析任务

## 常见问题

### Web 或桌面客户端连接不上后端怎么办？

先确认后端地址是否正确：

```bash
curl http://localhost:5000/api/upload
```

`/api/upload` 只支持 `POST` 上传文件，直接 `GET` 可能返回 404 或 405，但这至少能确认服务是否可达。运行客户端时请显式传入：

```bash
flutter run -d chrome --dart-define=BACKEND_URL=http://localhost:5000
```

### Android 模拟器为什么不能访问 `localhost:5000`？

Android 模拟器里的 `localhost` 指模拟器自身，不是电脑宿主机。请使用：

```bash
flutter run -d android --dart-define=BACKEND_URL=http://10.0.2.2:5000
```

真机调试时，请把 `BACKEND_URL` 改成电脑在同一局域网中的 IP 地址。

### 上传成功后没有出现分析按钮怎么办？

请确认后端上传接口返回了 `filepath` 字段。当前客户端兼容：

```json
{ "filepath": "uploads/example.csv" }
```

以及：

```json
{ "data": { "filepath": "uploads/example.csv" } }
```

### 结节检测失败怎么办？

结节检测任务依赖 CSV 中的 `SN` 列。请确认 CSV 同时包含 `SN` 和 `MAT_0` 到 `MAT_95`。

### 调用原生 DPI 信息失败怎么办？

部分平台暂未实现 `getNativeScaleInfo` 的原生代码时，页面会显示调用失败信息。当前代码中 Android、iOS、Windows 已有 MethodChannel 实现；Web、Linux、macOS 可能需要后续补充。

## 贡献指南

这是个人项目，暂未开放完整贡献流程。如需协作，请先提交 issue 或联系维护者。

## License

当前项目暂未包含 `LICENSE` 文件。公开发布前请确认使用 MIT、Apache-2.0 或其他许可证。
