// file: lib/app_state.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:http_parser/http_parser.dart';

class AppState extends ChangeNotifier {
  // 定义与原生端完全相同的 MethodChannel 名称
  static const _nativeScaleChannel = MethodChannel(
    'com.example.myapp/native_scale_control',
  );
  static const _defaultBackendUrl = 'http://localhost:5000';
  static const _configuredBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: _defaultBackendUrl,
  );

  // --- 状态变量 ---

  final String _backendUrl = _normalizeBackendUrl(_configuredBackendUrl);

  String _uploadStatus = '等待上传文件...';
  String? _serverFilepath;
  bool _isProcessing = false;
  double _progress = 0.0;
  String _progressText = '';
  dynamic _resultUrl; // 分析结果 (String或Map)
  io.Socket? _socket;
  String _nativeScaleInfo = '尚未获取原生缩放信息';
  String _platformName = '未知平台';

  // --- UI 使用的 Getters ---

  String get uploadStatus => _uploadStatus;
  String? get serverFilepath => _serverFilepath;
  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  String get progressText => _progressText;
  dynamic get resultUrl => _resultUrl;
  String get nativeScaleInfo => _nativeScaleInfo;
  String get platformName => _platformName;
  // --- 构造函数和 WebSocket 初始化 ---

  AppState({bool connectOnStart = true}) {
    if (connectOnStart) {
      _connectWebSocket();
    }
    _determinePlatform();
  }

  static String _normalizeBackendUrl(String value) {
    final trimmed = value.trim();
    final url = trimmed.isEmpty ? _defaultBackendUrl : trimmed;
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  void _determinePlatform() {
    if (kIsWeb) {
      _platformName = 'Web';
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      _platformName = 'Android';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      _platformName = 'iOS';
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      _platformName = 'Windows';
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      _platformName = 'macOS';
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      _platformName = 'Linux';
    }
  }

  void _connectWebSocket() {
    // 确保URL正确，特别是对于SocketIO
    _socket = io.io(_backendUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket?.connect();

    _socket?.onConnect((_) => debugPrint('WebSocket Connected'));
    _socket?.onDisconnect((_) => debugPrint('WebSocket Disconnected'));

    // 监听 'progress_update' 事件 (与后端匹配，无需修改)
    _socket?.on('progress_update', (data) {
      if (data is Map && data.containsKey('progress')) {
        _progress = (data['progress'] as num).toDouble();
        _progressText = '正在处理中... ${_progress.toStringAsFixed(0)}%';
        notifyListeners();
      }
    });

    // 监听 'task_complete' 事件 (与后端匹配，无需修改)
    _socket?.on('task_complete', (data) {
      if (data is Map && data.containsKey('result_url')) {
        _resultUrl = data['result_url'];

        _isProcessing = false;
        _progress = 100.0;
        _progressText = '处理完成！';
        notifyListeners();
      }
    });

    // 监听 'error' 事件 (与后端匹配，无需修改)
    _socket?.on('error', (data) {
      String errorMessage = '发生未知服务器错误';
      if (data is Map && data.containsKey('message')) {
        errorMessage = data['message'];
      } else {
        errorMessage = data.toString();
      }
      _uploadStatus = '服务器错误: $errorMessage'; // 在上传区域显示错误
      _isProcessing = false; // 停止处理状态
      notifyListeners();
    });
  }

  // --- UI 调用的方法 ---
  /// 调用原生代码获取特定平台的缩放/DPI信息
  Future<void> fetchNativeScaleInfo() async {
    String scaleInfo;
    try {
      // 调用原生层名为 'getNativeScaleInfo' 的方法
      final String result = await _nativeScaleChannel.invokeMethod(
        'getNativeScaleInfo',
      );
      scaleInfo = '成功: \n$result';
    } on PlatformException catch (e) {
      scaleInfo =
          "调用失败: '${e.message}'.\n请确保您已在当前平台（$_platformName）的原生代码中实现了此功能。";
    }
    // 更新状态并通知UI刷新
    _nativeScaleInfo = scaleInfo;
    notifyListeners();
  }

  String getServerUrl(String path) {
    // 后端返回的路径如 /api/results/xyz.gif, 我们需要拼接成 http://.../api/results/xyz.gif
    // 这里的逻辑可以正确处理带'/'和不带'/'的路径
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$_backendUrl/$cleanPath';
  }

  Future<void> pickAndUploadFile() async {
    // 重置状态
    _serverFilepath = null;
    _resultUrl = null;
    _isProcessing = false;
    _uploadStatus = '正在选择文件...';
    notifyListeners();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: kIsWeb,
    );

    if (result == null || result.files.isEmpty) {
      _uploadStatus = '未选择文件';
      notifyListeners();
      return;
    }

    PlatformFile selectedFile = result.files.first;
    _uploadStatus = '正在上传: ${selectedFile.name}';
    notifyListeners();

    try {
      // 使用正确的上传URL '/api/upload' (与后端匹配，无需修改)
      var uri = Uri.parse('$_backendUrl/api/upload');
      var request = http.MultipartRequest('POST', uri);

      // 使用正确的字段名 'file' (与后端匹配，无需修改)
      final fieldName = 'file';

      if (kIsWeb) {
        if (selectedFile.bytes == null) throw Exception('Web平台文件字节为空');
        request.files.add(
          http.MultipartFile.fromBytes(
            fieldName,
            selectedFile.bytes!,
            filename: selectedFile.name,
            contentType: MediaType('text', 'csv'),
          ),
        );
      } else {
        if (selectedFile.path == null) throw Exception('文件路径为空');
        request.files.add(
          await http.MultipartFile.fromPath(
            fieldName,
            selectedFile.path!,
            filename: selectedFile.name,
            contentType: MediaType('text', 'csv'),
          ),
        );
      }

      var response = await request.send();

      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);

        // 兼容当前 Flask 后端的顶层 filepath，以及可能存在的 data.filepath 响应结构。
        final filepath =
            jsonResponse['filepath'] ?? jsonResponse['data']?['filepath'];
        if (filepath is String && filepath.isNotEmpty) {
          _serverFilepath = filepath;
          _uploadStatus = '文件上传成功！请选择一个分析任务。';
        } else {
          _uploadStatus = '上传失败: ${jsonResponse['error'] ?? '未知响应格式'}';
        }
      } else {
        _uploadStatus = '上传失败: ${response.statusCode} - $responseBody';
      }
    } catch (e) {
      _uploadStatus = '上传出错: $e';
    } finally {
      notifyListeners();
    }
  }

  void startProcessing(String taskType) {
    if (_serverFilepath == null) {
      _uploadStatus = '错误：没有已上传的文件可供分析。';
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _progress = 0.0;
    _progressText = '任务已提交，等待服务器响应...';
    _resultUrl = null;
    notifyListeners();

    // 发送 'start_processing' 事件和正确的数据结构 (与后端匹配，无需修改)
    _socket?.emit('start_processing', {
      'filepath': _serverFilepath,
      'task': taskType,
    });
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }
}
