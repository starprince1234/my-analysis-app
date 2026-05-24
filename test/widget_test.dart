import 'package:analysis/app_state.dart';
import 'package:analysis/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home page shows upload and system info sections', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(appState: AppState(connectOnStart: false)));

    expect(find.text('多功能分析平台'), findsWidgets);
    expect(find.text('1. 上传CSV数据文件'), findsOneWidget);
    expect(find.text('系统缩放/DPI信息'), findsOneWidget);
    expect(find.text('等待上传文件...'), findsOneWidget);
  });
}
