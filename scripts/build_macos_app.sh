#!/bin/bash
# 构建 macOS 包（支持选择打 计数器1 / 计数器2 / 两者）
# 用法:
#   ./scripts/build_macos_copy.sh        # 打两个

set -e
cd "$(dirname "$0")/.."

CONFIGS="macos/Runner/Configs"
ORIGIN="$CONFIGS/AppInfo.xcconfig"
MAIN="$CONFIGS/AppInfo.main.xcconfig"
COPY="$CONFIGS/AppInfo.copy.xcconfig"
OUTPUT="build/macos/Build/Products/Release"
export FLUTTER_XCODE_BUILD_DESTINATION="platform=macOS,arch=arm64"

# 解析参数：1=计数器1, 2=计数器2, 空或 both=两个都打
TARGET="${1:-both}"

build_app1() {
  cp "$MAIN" "$ORIGIN"
  echo ">>> 构建 计数器1..."
  fvm flutter build macos --release
}

build_app2() {
  cp "$COPY" "$ORIGIN"
  echo ">>> 构建 计数器2..."
  fvm flutter build macos --release
}

case "$TARGET" in
  1)
    build_app1
    echo ""
    echo "完成: $OUTPUT/计数器1.app"
    ;;
  2)
    build_app2
    echo ""
    echo "完成: $OUTPUT/计数器2.app"
    ;;
  both|"")
    # 先打 2，再打 1（否则 1 会覆盖 2）
    build_app2
    TMP_APP2="/tmp/计数器2_$$.app"
    [ -d "$OUTPUT/计数器2.app" ] && cp -R "$OUTPUT/计数器2.app" "$TMP_APP2"
    build_app1
    [ -d "$TMP_APP2" ] && cp -R "$TMP_APP2" "$OUTPUT/计数器2.app" && rm -rf "$TMP_APP2"
    echo ""
    echo "完成。两个安装包："
    echo "  - $OUTPUT/计数器1.app  (Bundle ID: com.like.flutterYcd)"
    echo "  - $OUTPUT/计数器2.app  (Bundle ID: com.like.flutterYcd2)"
    ;;
  *)
    echo "用法: $0 [1|2|both]"
    echo "  1   = 只打 计数器1"
    echo "  2   = 只打 计数器2"
    echo "  both = 打两个（默认）"
    exit 1
    ;;
esac
