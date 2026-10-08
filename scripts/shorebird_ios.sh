#!/bin/bash
# 用 Shorebird 发布 iOS 包或热更新补丁。
# iOS 只有一个包（com.like.flutterYcd），使用数策1 的 app_id。
# 用法:
#   ./scripts/shorebird_ios.sh release
#   ./scripts/shorebird_ios.sh patch
#   ./scripts/shorebird_ios.sh release http://192.168.1.5:3000/api
#
# release 会导出 ad-hoc IPA，并上传到 Shorebird。
# patch 只上传补丁，版本号必须和对应 release 一致。

set -euo pipefail
cd "$(dirname "$0")/.."

MODE="${1:-}"
API_URL_ARG="${2:-}"
SHOREBIRD="${SHOREBIRD:-shorebird}"
EXPORT_PLIST="ios/ExportOptions-adhoc.plist"

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export LANGUAGE="${LANGUAGE:-en_US.UTF-8}"

usage() {
  echo "用法: $0 <release|patch> [API_BASE_URL]"
  exit 1
}

case "$MODE" in
  release|patch) ;;
  *) usage ;;
esac

if [ ! -f "$EXPORT_PLIST" ]; then
  echo "缺少导出配置: $EXPORT_PLIST"
  exit 1
fi

cp shorebird/shorebird.main.yaml shorebird.yaml

EXTRA=()
if [ -n "$API_URL_ARG" ]; then
  echo ">>> 使用 API_BASE_URL=$API_URL_ARG"
  EXTRA=(--dart-define="API_BASE_URL=$API_URL_ARG")
fi

echo ">>> pod install"
(
  cd ios
  export LANG="${LANG:-en_US.UTF-8}"
  export LC_ALL="${LC_ALL:-en_US.UTF-8}"
  pod install
)

echo ">>> Shorebird $MODE ios..."
if [ "$MODE" = "release" ]; then
  "$SHOREBIRD" release ios \
    --flutter-version=fvm \
    --export-options-plist="$EXPORT_PLIST" \
    ${EXTRA[@]+"${EXTRA[@]}"}
else
  "$SHOREBIRD" patch ios \
    --release-version=latest \
    --export-options-plist="$EXPORT_PLIST" \
    ${EXTRA[@]+"${EXTRA[@]}"}
fi

echo ""
echo "完成：Shorebird $MODE ios"
