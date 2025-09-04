import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // 设置标题栏颜色为紫色（与AppBar完全一致）
    if #available(macOS 10.14, *) {
      self.titlebarAppearsTransparent = true
      self.titleVisibility = .hidden

      // 微调颜色，使其与AppBar更接近
      // 基于AppBar的颜色，稍微调亮一点
      self.backgroundColor = NSColor(red: 211.0/255.0, green: 188.0/255.0, blue: 253.0/255.0, alpha: 1.0)

      // 设置标题栏按钮颜色
      self.standardWindowButton(.closeButton)?.contentTintColor = NSColor.white
      self.standardWindowButton(.miniaturizeButton)?.contentTintColor = NSColor.white
      self.standardWindowButton(.zoomButton)?.contentTintColor = NSColor.white
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
