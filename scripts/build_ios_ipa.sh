#!/bin/bash
# 构建 iOS ad-hoc IPA（release-testing）
# 用法:
#   ./scripts/build_ios_ipa.sh
#   ./scripts/build_ios_ipa.sh http://192.168.1.5:3000/api

set -euo pipefail
cd "$(dirname "$0")/.."

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export LANGUAGE="${LANGUAGE:-en_US.UTF-8}"

API_URL_ARG="${1:-}"
ARCHIVE="build/ios/archive/Runner.xcarchive"
EXPORT_PLIST="ios/ExportOptions-adhoc.plist"
OUT_DIR="build/ios/ipa"

FLUTTER_EXTRA=()
if [ -n "$API_URL_ARG" ]; then
  echo ">>> 使用 API_BASE_URL=$API_URL_ARG"
  FLUTTER_EXTRA=(--dart-define="API_BASE_URL=$API_URL_ARG")
fi

if [ ! -f "$EXPORT_PLIST" ]; then
  echo "缺少导出配置: $EXPORT_PLIST"
  exit 1
fi

echo ">>> flutter pub get"
fvm flutter pub get

echo ">>> pod install"
(
  cd ios
  export LANG="${LANG:-en_US.UTF-8}"
  export LC_ALL="${LC_ALL:-en_US.UTF-8}"
  pod install
)

echo ">>> flutter build ipa (archive)"
set +e
if [ ${#FLUTTER_EXTRA[@]} -gt 0 ]; then
  fvm flutter build ipa --release "${FLUTTER_EXTRA[@]}"
else
  fvm flutter build ipa --release
fi
flutter_status=$?
set -e

if [ ! -d "$ARCHIVE" ]; then
  echo "未生成 xcarchive，flutter build ipa 退出码: $flutter_status"
  exit 1
fi

echo ">>> xcodebuild exportArchive"
rm -rf "$OUT_DIR"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$OUT_DIR" \
  -exportOptionsPlist "$EXPORT_PLIST"

IPA_FILE="$(find "$OUT_DIR" -maxdepth 1 -name '*.ipa' | head -1)"
if [ -z "$IPA_FILE" ] || [ ! -f "$IPA_FILE" ]; then
  echo "未找到导出的 IPA"
  ls -lah "$OUT_DIR" || true
  exit 1
fi

echo ">>> IPA 已生成: $IPA_FILE"
ls -lh "$IPA_FILE"
