import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

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

    super.awakeFromNib()
  }
}
