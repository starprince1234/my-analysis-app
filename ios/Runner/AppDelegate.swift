import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 1. 获取FlutterViewController
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

    // 2. 定义与Flutter端完全相同的Channel名称
    let nativeScaleChannel = FlutterMethodChannel(name: "com.example.myapp/native_scale_control",
                                              binaryMessenger: controller.binaryMessenger)

    // 3. 设置处理器
    nativeScaleChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      // 检查方法名
      guard call.method == "getNativeScaleInfo" else {
        result(FlutterMethodNotImplemented)
        return
      }

      // 4. 调用iOS原生API实现独有功能
      let mainScreen = UIScreen.main
      let scale = mainScreen.scale // 点(Point)与像素(Pixel)的比例
      let nativeScale = mainScreen.nativeScale // 屏幕硬件的真实像素比例

      let info = """
          实现方式: Swift 调用 UIScreen
          逻辑缩放因子 (scale): \(scale)
          物理缩放因子 (nativeScale): \(nativeScale)
          屏幕尺寸 (Points): \(mainScreen.bounds.size)
      """

      // 5. 将结果返回给Flutter
      result(info)
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
