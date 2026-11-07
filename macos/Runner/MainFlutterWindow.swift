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
      // 让独立于本应用的 shell 延迟调用 open。旧进程先完全退出，LaunchServices
      // 才不会把打开请求交回仍在终止中的旧实例。
      let relauncher = Process()
      relauncher.executableURL = URL(fileURLWithPath: "/bin/sh")
      relauncher.arguments = [
        "-c",
        "sleep 1; exec /usr/bin/open -n \"$1\"",
        "ycd-restart",
        Bundle.main.bundleURL.path,
      ]
      relauncher.standardOutput = FileHandle.nullDevice
      relauncher.standardError = FileHandle.nullDevice

      do {
        try relauncher.run()
        result(nil)
        DispatchQueue.main.async {
          NSApp.terminate(nil)
        }
      } catch {
        result(FlutterError(code: "restart_failed", message: error.localizedDescription, details: nil))
      }
    }

    super.awakeFromNib()
  }
}
