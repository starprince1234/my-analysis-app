package com.example.analysis;

import androidx.annotation.NonNull; // 导入NonNull注解
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.util.DisplayMetrics; // 导入DisplayMetrics类
import android.view.Display;       // 导入Display类 (虽然DisplayMetrics可以直接从Resources获取，但为了获取默认Display也可以用)
import android.view.WindowManager; // 导入WindowManager类

public class MainActivity extends FlutterActivity {
    // 声明与 Flutter 端一致的 MethodChannel 名称
    private static final String CHANNEL = "com.example.myapp/native_scale_control";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // 创建 MethodChannel 并设置方法调用处理器
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        new MethodChannel.MethodCallHandler() {
                            @Override
                            public void onMethodCall(@NonNull io.flutter.plugin.common.MethodCall call, @NonNull MethodChannel.Result result) {
                                // 检查调用的方法名
                                if (call.method.equals("getNativeScaleInfo")) {
                                    // 调用获取原生缩放信息的方法
                                    String scaleInfo = getNativeScaleInfo();
                                    // 将结果发送回 Flutter
                                    result.success(scaleInfo);
                                } else {
                                    // 如果方法未实现，通知 Flutter
                                    result.notImplemented();
                                }
                            }
                        }
                );
    }

    // 获取原生缩放/DPI信息的私有方法
    private String getNativeScaleInfo() {
        DisplayMetrics displayMetrics = new DisplayMetrics();
        // 获取当前设备的显示信息
        // getWindowManager().getDefaultDisplay().getMetrics(displayMetrics); // 适用于API level 17及以上

        // 更通用的方法，通过资源获取DisplayMetrics
        displayMetrics = getResources().getSystem().getDisplayMetrics();


        StringBuilder sb = new StringBuilder();
        sb.append("Android Display Metrics:\n");
        sb.append("  密度 (density): ").append(displayMetrics.density).append("\n");
        sb.append("  密度DPI (densityDpi): ").append(displayMetrics.densityDpi).append(" dpi\n");
        sb.append("  字体缩放密度 (scaledDensity): ").append(displayMetrics.scaledDensity).append("\n");
        sb.append("  屏幕宽度 (widthPixels): ").append(displayMetrics.widthPixels).append(" px\n");
        sb.append("  屏幕高度 (heightPixels): ").append(displayMetrics.heightPixels).append(" px\n");
        sb.append("  X方向DPI (xdpi): ").append(displayMetrics.xdpi).append(" dpi\n");
        sb.append("  Y方向DPI (ydpi): ").append(displayMetrics.ydpi).append(" dpi");

        return sb.toString();
    }
}
