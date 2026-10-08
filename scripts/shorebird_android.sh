#!/bin/bash
# 用 Shorebird 发布 Android 包或热更新补丁。
# Android 只有一个包（com.like.flutter_ycd），使用数策1 的 app_id。只打 arm64。
# 用法:
#   ./scripts/shorebird_android.sh release
#   ./scripts/shorebird_android.sh patch
#   ./scripts/shorebird_android.sh release http://192.168.1.5:3000/api
#
# release 会上传 AAB，并额外打出可安装的 APK（build/app/outputs/flutter-apk/app-release.apk）。
# patch 只上传补丁。Shorebird 不支持 split-per-abi，所以 APK 不按 ABI 拆分，内容仍只有 arm64。

set -euo pipefail
cd "$(dirname "$0")/.."

MODE="${1:-}"
API_URL_ARG="${2:-}"
SHOREBIRD="${SHOREBIRD:-shorebird}"

usage() {
  echo "用法: $0 <release|patch> [API_BASE_URL]"
  exit 1
}

case "$MODE" in
  release|patch) ;;
  *) usage ;;
esac

cp shorebird/shorebird.main.yaml shorebird.yaml

EXTRA=()
if [ -n "$API_URL_ARG" ]; then
  echo ">>> 使用 API_BASE_URL=$API_URL_ARG"
  EXTRA=(--dart-define="API_BASE_URL=$API_URL_ARG")
fi

echo ">>> Shorebird $MODE android (arm64)..."
if [ "$MODE" = "release" ]; then
  "$SHOREBIRD" release android \
    --flutter-version=fvm \
    --artifact apk \
    --target-platform android-arm64 \
    ${EXTRA[@]+"${EXTRA[@]}"}
  APK="build/app/outputs/flutter-apk/app-release.apk"
  if [ ! -f "$APK" ]; then
    echo "未找到 APK: $APK"
    ls -lah build/app/outputs/flutter-apk || true
    exit 1
  fi
  echo ">>> APK 已生成: $APK"
  ls -lh "$APK"
else
  "$SHOREBIRD" patch android \
    --release-version=latest \
    ${EXTRA[@]+"${EXTRA[@]}"} \
    -- --target-platform=android-arm64
fi

echo ""
echo "完成：Shorebird $MODE android"
