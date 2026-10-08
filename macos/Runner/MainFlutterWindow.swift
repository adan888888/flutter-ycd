import Cocoa
import FlutterMacOS

/// macOS 启动窗口尺寸（内容区宽高，单位 pt）。可按需要改这里。
private let kDefaultWindowWidth: CGFloat = 320
private let kDefaultWindowHeight: CGFloat = 640

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // 覆盖 MainMenu.xib 里的默认尺寸，避免 Mac 上首次打开过宽
    let contentSize = NSSize(width: kDefaultWindowWidth, height: kDefaultWindowHeight)
    self.setContentSize(contentSize)
    self.center()

    // 设置标题栏透明，并让内容延伸至标题栏区域
    if #available(macOS 10.14, *) {
      self.titlebarAppearsTransparent = true
      self.titleVisibility = .hidden
      self.styleMask.insert(.fullSizeContentView)

      // 设置标题栏按钮颜色
      self.standardWindowButton(.closeButton)?.contentTintColor = NSColor.white
      self.standardWindowButton(.miniaturizeButton)?.contentTintColor = NSColor.white
      self.standardWindowButton(.zoomButton)?.contentTintColor = NSColor.white
    }

    RegisterGeneratedPlugins(registry: flutterViewController)
    let restartChannel = FlutterMethodChannel(
      name: "ycd/app_restart",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    restartChannel.setMethodCallHandler { call, result in
      guard call.method == "restart" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let config = NSWorkspace.OpenConfiguration()
      config.createsNewApplicationInstance = true
      NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: config) { _, error in
        if let error = error {
          result(FlutterError(code: "restart_failed", message: error.localizedDescription, details: nil))
          return
        }
        result(nil)
        DispatchQueue.main.async {
          NSApp.terminate(nil)
        }
      }
    }

    super.awakeFromNib()
  }
}
