import UIKit
import Flutter
import UserNotifications
import Darwin

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
        // 测试包、不上架：用私有接口让系统重新打开本应用，补丁才会在新进程里生效。
        if self.relaunchWithPrivateAPI(result: result) {
          return
        }
        self.scheduleRestartNotification(result: result)
      }
    }
    return launched
  }

  /// 先把应用挂到后台，再让 LaunchServices 按 Bundle ID 重新打开，然后退出当前进程。
  /// `LSApplicationWorkspace` 和 `UIApplication.suspend` 都是私有接口，不能用于上架包。
  private func relaunchWithPrivateAPI(result: @escaping FlutterResult) -> Bool {
    dlopen("/System/Library/Frameworks/CoreServices.framework/CoreServices", RTLD_NOW)
    dlopen("/System/Library/PrivateFrameworks/CoreServices.framework/CoreServices", RTLD_NOW)

    guard NSClassFromString("LSApplicationWorkspace") != nil,
          Bundle.main.bundleIdentifier != nil else {
      return false
    }

    let application = UIApplication.shared
    let suspend = NSSelectorFromString("suspend")
    if application.responds(to: suspend) {
      application.perform(suspend)
    }

    result(nil)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
      self.openOwnApplication()
      exit(0)
    }
    return true
  }

  private func openOwnApplication() {
    guard let workspaceClass = NSClassFromString("LSApplicationWorkspace"),
          let bundleID = Bundle.main.bundleIdentifier else {
      return
    }
    typealias ClassMessage = @convention(c) (AnyClass, Selector) -> Unmanaged<AnyObject>?
    typealias OpenMessage = @convention(c) (AnyObject, Selector, NSString) -> Bool
    guard let symbol = dlsym(dlopen("/usr/lib/libobjc.A.dylib", RTLD_NOW), "objc_msgSend") else {
      return
    }
    let workspace = unsafeBitCast(symbol, to: ClassMessage.self)(
      workspaceClass,
      NSSelectorFromString("defaultWorkspace")
    )?.takeUnretainedValue()
    guard let workspace else { return }
    _ = unsafeBitCast(symbol, to: OpenMessage.self)(
      workspace,
      NSSelectorFromString("openApplicationWithBundleID:"),
      bundleID as NSString
    )
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
