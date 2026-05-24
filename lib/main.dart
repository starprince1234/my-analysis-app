import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.appState});

  final AppState? appState;

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: '多功能分析平台',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );

    if (appState == null) {
      return app;
    }

    return ChangeNotifierProvider<AppState>.value(value: appState!, child: app);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度，用于给 InteractiveViewer 的子元素设定一个明确的宽度
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('多功能分析平台'),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            tooltip: '重置视图',
            onPressed: () {
              _transformationController.value = Matrix4.identity();
            },
          ),
        ],
      ),
      body: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 4.0,
        // boundaryMargin 和 constrained 的设置保持不变，它们控制平移行为
        boundaryMargin: const EdgeInsets.all(double.infinity),
        constrained: false, // 允许内容不被边界限制，配合infinity margin可以无限平移
        // ==================【核心修改】==================
        // 1. 移除 SingleChildScrollView
        // 2. 使用 Padding 重新应用原始的边距
        // 3. 使用 SizedBox 强制 Column 占据屏幕宽度
        child: Padding(
          padding: const EdgeInsets.all(
            16.0,
          ), // 原 SingleChildScrollView 的 padding
          child: SizedBox(
            width: screenWidth, // 强制 Column 占据屏幕的宽度
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 保持原有对齐方式
              children: [
                // 卡片1: 文件上传
                buildUploadCard(context),
                const SizedBox(height: 20),

                // 卡片2: 分析任务控制 (根据状态显示)
                buildControlsCard(context),
                const SizedBox(height: 20),

                // 卡片3: 进度条 (根据状态显示)
                buildProgressCard(context),
                const SizedBox(height: 20),

                // 卡片4: 结果展示 (根据状态显示)
                buildResultCard(context),
                // 卡片5: 缩放按钮
                const SizedBox(height: 20),
                buildSystemInfoCard(context),
              ],
            ),
          ),
        ),
        // ===============================================
      ),
    );
  }

  // 以下是构建各个卡片UI的函数 (保持不变)
  Widget buildSystemInfoCard(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '系统缩放/DPI信息',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '当前平台: ${appState.platformName}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.important_devices),
                  label: const Text('获取原生缩放/DPI信息'),
                  onPressed: () => appState.fetchNativeScaleInfo(),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    appState.nativeScaleInfo,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildUploadCard(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. 上传CSV数据文件',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('选择文件'),
              onPressed: appState.pickAndUploadFile,
            ),
            const SizedBox(height: 10),
            Text(appState.uploadStatus),
          ],
        ),
      ),
    );
  }

  Widget buildControlsCard(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    if (appState.serverFilepath == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '2. 选择并开始分析任务',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () => appState.startProcessing('stress'),
                  child: const Text('应力分析动画'),
                ),
                ElevatedButton(
                  onPressed: () => appState.startProcessing('nodule'),
                  child: const Text('结节检测动画'),
                ),
                ElevatedButton(
                  onPressed: () => appState.startProcessing('stats'),
                  child: const Text('统计特征分析'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProgressCard(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    if (!appState.isProcessing) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '3. 处理进度',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: appState.progress / 100),
            const SizedBox(height: 10),
            Text(appState.progressText),
          ],
        ),
      ),
    );
  }

  Widget buildResultCard(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    if (appState.resultUrl == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '4. 分析结果',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // 根据结果类型动态构建内容
            if (appState.resultUrl is String)
              Image.network(appState.getServerUrl(appState.resultUrl)),

            if (appState.resultUrl is Map) ...[
              Image.network(appState.getServerUrl(appState.resultUrl['image'])),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey[200],
                child: SelectableText(appState.resultUrl['report']),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
