import UIKit
import Flutter
import UserNotifications

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
        // iOS 没有重新打开本应用的公开接口。先发一条本地通知，再退出进程，
        // 用户点通知后系统会重新启动应用，补丁才会生效。
        self.scheduleRestartNotification(result: result)
      }
    }
    return launched
  }

  private func scheduleRestartNotification(result: @escaping FlutterResult) {
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings { settings in
      DispatchQueue.main.async {
        switch settings.authorizationStatus {
        case .authorized, .provisional:
          self.postRestartNotification(result: result)
        case .notDetermined:
          center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
              if granted {
                self.postRestartNotification(result: result)
              } else {
                result(nil)
                exit(0)
              }
            }
          }
        default:
          result(nil)
          exit(0)
        }
      }
    }
  }

  private func postRestartNotification(result: @escaping FlutterResult) {
    let content = UNMutableNotificationContent()
    content.title = "更新已就绪"
    content.body = "点按通知重新打开数策"
    content.sound = .default
    let request = UNNotificationRequest(
      identifier: "ycd_restart",
      content: content,
      trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    )
    UNUserNotificationCenter.current().add(request) { error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(code: "restart_failed", message: error.localizedDescription, details: nil))
          exit(0)
          return
        }
        result(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          exit(0)
        }
      }
    }
  }
}
