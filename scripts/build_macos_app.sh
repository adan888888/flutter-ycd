#!/bin/bash
# 构建 macOS 包（计数器1 / 计数器2 / 计数器3）
# 原理：就是通过 xcconfig（具体是覆盖 AppInfo.xcconfig）在每次编译前切换 PRODUCT_BUNDLE_IDENTIFIER 和 PRODUCT_NAME，从而打出不同 Bundle ID、不同名字的 .app。
# 用法:
#   ./scripts/build_macos_app.sh              # 默认：计数器1 + 计数器2（与以前一致）
#   ./scripts/build_macos_app.sh 1            # 只打 计数器1
#   ./scripts/build_macos_app.sh 2            # 只打 计数器2
#   ./scripts/build_macos_app.sh 3            # 只打 计数器3
#   ./scripts/build_macos_app.sh all          # 三个都打
#
# 第二个参数：后端地址（可选）
#   ./scripts/build_macos_app.sh all http://192.168.1.5:3000/api

set -e
cd "$(dirname "$0")/.."

CONFIGS="macos/Runner/Configs"
ORIGIN="$CONFIGS/AppInfo.xcconfig"
MAIN="$CONFIGS/AppInfo.main.xcconfig"
COPY="$CONFIGS/AppInfo.copy.xcconfig"
COPY3="$CONFIGS/AppInfo.copy3.xcconfig"
OUTPUT="build/macos/Build/Products/Release"
export FLUTTER_XCODE_BUILD_DESTINATION="platform=macOS,arch=arm64"

TARGET="${1:-both}"
API_URL_ARG="${2:-}"

FLUTTER_EXTRA=()
if [ -n "$API_URL_ARG" ]; then
  echo ">>> 使用 API_BASE_URL=$API_URL_ARG"
  FLUTTER_EXTRA=(--dart-define="API_BASE_URL=$API_URL_ARG")
fi

build_app1() {
  cp "$MAIN" "$ORIGIN"
  echo ">>> 构建 计数器1..."
  fvm flutter build macos --release "${FLUTTER_EXTRA[@]}"
}

build_app2() {
  cp "$COPY" "$ORIGIN"
  echo ">>> 构建 计数器2..."
  fvm flutter build macos --release "${FLUTTER_EXTRA[@]}"
}

build_app3() {
  cp "$COPY3" "$ORIGIN"
  echo ">>> 构建 计数器3..."
  fvm flutter build macos --release "${FLUTTER_EXTRA[@]}"
}

# 先打副本（2、3），最后打主包 1，并把副本从 /tmp 拷回 Release
build_all_three() {
  build_app2
  TMP2="/tmp/计数器2_$$.app"
  [ -d "$OUTPUT/计数器2.app" ] && cp -R "$OUTPUT/计数器2.app" "$TMP2"

  build_app3
  TMP3="/tmp/计数器3_$$.app"
  [ -d "$OUTPUT/计数器3.app" ] && cp -R "$OUTPUT/计数器3.app" "$TMP3"

  build_app1

  [ -d "$TMP2" ] && cp -R "$TMP2" "$OUTPUT/计数器2.app" && rm -rf "$TMP2"
  [ -d "$TMP3" ] && cp -R "$TMP3" "$OUTPUT/计数器3.app" && rm -rf "$TMP3"

  echo ""
  echo "完成。三个安装包："
  echo "  - $OUTPUT/计数器1.app  (Bundle ID: com.like.flutterYcd)"
  echo "  - $OUTPUT/计数器2.app  (Bundle ID: com.like.flutterYcd2)"
  echo "  - $OUTPUT/计数器3.app  (Bundle ID: com.like.flutterYcd3)"
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
  3)
    build_app3
    echo ""
    echo "完成: $OUTPUT/计数器3.app"
    ;;
  all)
    build_all_three
    ;;
  both|"")
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
    echo "用法: $0 [1|2|3|both|all] [API_BASE_URL]"
    echo "  1|2|3   只打对应计数器"
    echo "  both    打 计数器1 + 计数器2（默认）"
    echo "  all     打 计数器1 + 计数器2 + 计数器3"
    echo "  第二个参数可选：后端地址，如 http://192.168.1.5:3000/api"
    exit 1
    ;;
esac
