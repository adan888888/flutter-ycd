import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      print("Documents Directory: \(documentsDirectory.path)")
    }
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "ycd/app_restart",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "restart" else {
          result(FlutterMethodNotImplemented)
          return
        }
        // iOS 不提供合规的程序化退出并重新启动能力。Dart 端不会调用这里，
        // 而是指引用户从应用切换器彻底关闭后手动重开。
        result(
          FlutterError(
            code: "manual_restart_required",
            message: "iOS requires the user to close and reopen the app.",
            details: nil
          )
        )
      }
    }
    return launched
  }
}
