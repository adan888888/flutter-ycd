#!/bin/bash
# 用 Shorebird 发布 macOS 包或热更新补丁（数策1 / 数策2 / 数策3）
# 原理：与 build_macos_app.sh 相同，每次编译前覆盖 AppInfo.xcconfig 切换 Bundle ID 和名字；
#       同时覆盖 shorebird.yaml 切换 app_id，三个数策各对应一个 Shorebird 应用。
# 用法:
#   ./scripts/shorebird_macos.sh release all                 # 三个都发布新版本（会产出 .app）
#   ./scripts/shorebird_macos.sh patch all                   # 三个都发热更新补丁
#   ./scripts/shorebird_macos.sh patch 1                     # 只给 数策1 发补丁
#   ./scripts/shorebird_macos.sh release all http://192.168.1.5:3000/api
#
# 注意：
#   - release 的版本号取 pubspec.yaml 的 version，同一版本只能 release 一次，发新版本前先改版本号。
#   - patch 默认打到最近一次 release；第三个参数（后端地址）要和对应 release 时保持一致。

set -euo pipefail
cd "$(dirname "$0")/.."

MODE="${1:-}"
TARGET="${2:-all}"
API_URL_ARG="${3:-}"
SHOREBIRD="${SHOREBIRD:-shorebird}"

CONFIGS="macos/Runner/Configs"
ORIGIN_XCCONFIG="$CONFIGS/AppInfo.xcconfig"
ORIGIN_YAML="shorebird.yaml"
OUTPUT="build/macos/Build/Products/Release"
export FLUTTER_XCODE_BUILD_DESTINATION="platform=macOS,arch=arm64"

EXTRA=()
if [ -n "$API_URL_ARG" ]; then
  echo ">>> 使用 API_BASE_URL=$API_URL_ARG"
  EXTRA=(--dart-define="API_BASE_URL=$API_URL_ARG")
fi

usage() {
  echo "用法: $0 <release|patch> [1|2|3|all] [API_BASE_URL]"
  exit 1
}

case "$MODE" in
  release|patch) ;;
  *) usage ;;
esac

# 数策编号 -> xcconfig / shorebird.yaml / .app 名称
variant_suffix() {
  case "$1" in
    1) echo "main" ;;
    2) echo "copy" ;;
    3) echo "copy3" ;;
  esac
}

build_variant() {
  local n="$1"
  local suffix
  suffix="$(variant_suffix "$n")"
  local yaml="shorebird/shorebird.$suffix.yaml"
  if [ ! -f "$yaml" ]; then
    echo "缺少 $yaml，请先为 数策$n 执行 shorebird init"
    exit 1
  fi
  cp "$CONFIGS/AppInfo.$suffix.xcconfig" "$ORIGIN_XCCONFIG"
  cp "$yaml" "$ORIGIN_YAML"
  # 同一目录里如果还留着其他数策的 .app，Shorebird 会拿错包，
  # 从而报 shorebird.yaml 和已发布版本不一致。
  rm -rf "$OUTPUT"/数策*.app
  echo ">>> Shorebird $MODE 数策$n..."
  if [ "$MODE" = "release" ]; then
    "$SHOREBIRD" release macos --flutter-version=fvm ${EXTRA[@]+"${EXTRA[@]}"}
  else
    "$SHOREBIRD" patch macos --release-version=latest ${EXTRA[@]+"${EXTRA[@]}"}
  fi
}

# 先做副本（2、3），最后做主包 1，release 时把副本 .app 从 /tmp 拷回 Release
run_variant() {
  local n="$1"
  build_variant "$n"
  if [ "$MODE" = "release" ] && [ "$n" != "1" ] && [ -d "$OUTPUT/数策$n.app" ]; then
    rm -rf "/tmp/数策${n}_$$.app"
    cp -R "$OUTPUT/数策$n.app" "/tmp/数策${n}_$$.app"
  fi
}

restore_copies() {
  for n in 2 3; do
    if [ -d "/tmp/数策${n}_$$.app" ]; then
      rm -rf "$OUTPUT/数策$n.app"
      cp -R "/tmp/数策${n}_$$.app" "$OUTPUT/数策$n.app"
      rm -rf "/tmp/数策${n}_$$.app"
    fi
  done
}

case "$TARGET" in
  1|2|3)
    run_variant "$TARGET"
    ;;
  all)
    run_variant 2
    run_variant 3
    run_variant 1
    restore_copies
    ;;
  *)
    usage
    ;;
esac

echo ""
echo "完成：Shorebird $MODE 数策 $TARGET"
if [ "$MODE" = "release" ]; then
  ls -d "$OUTPUT"/数策*.app 2>/dev/null || true
fi
