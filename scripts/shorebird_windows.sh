#!/bin/bash
# 用 Shorebird 发布 Windows 包或热更新补丁。
# Windows 只有一个包，使用数策1 的 app_id。程序名是「天才交易员」。
# 用法:
#   ./scripts/shorebird_windows.sh release
#   ./scripts/shorebird_windows.sh patch
#   ./scripts/shorebird_windows.sh build
#   ./scripts/shorebird_windows.sh release http://192.168.1.5:3000/api
#
# release 会打出 build/windows/x64/runner/Release/天才交易员.exe，并上传到 Shorebird。
# patch 只上传补丁，版本号必须和对应 release 一致。
# build 只在本地打安装目录，不上传。
# Shorebird 和 Flutter 都只能在 Windows 上打这个包。

set -euo pipefail
cd "$(dirname "$0")/.."

MODE="${1:-}"
API_URL_ARG="${2:-}"
SHOREBIRD="${SHOREBIRD:-shorebird}"
RELEASE_DIR="build/windows/x64/runner/Release"
EXE="$RELEASE_DIR/天才交易员.exe"

usage() {
  echo "用法: $0 <release|patch|build> [API_BASE_URL]"
  exit 1
}

case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*|Windows*) ;;
  *)
    echo "Windows 包只能在 Windows 上打。当前系统是 $(uname -s)。"
    echo "这台 Mac 上的 Jenkins 打不了 Windows 包。"
    exit 1
    ;;
esac

case "$MODE" in
  release|patch|build) ;;
  *) usage ;;
esac

if [ "$MODE" != "build" ]; then
  cp shorebird/shorebird.main.yaml shorebird.yaml
fi

EXTRA=()
if [ -n "$API_URL_ARG" ]; then
  echo ">>> 使用 API_BASE_URL=$API_URL_ARG"
  EXTRA=(--dart-define="API_BASE_URL=$API_URL_ARG")
fi

echo ">>> $MODE windows..."
if [ "$MODE" = "release" ]; then
  "$SHOREBIRD" release windows \
    --flutter-version=fvm \
    ${EXTRA[@]+"${EXTRA[@]}"}
elif [ "$MODE" = "patch" ]; then
  "$SHOREBIRD" patch windows \
    --release-version=latest \
    ${EXTRA[@]+"${EXTRA[@]}"}
elif [ -n "$API_URL_ARG" ]; then
  fvm flutter build windows --release ${EXTRA[@]+"${EXTRA[@]}"}
else
  fvm flutter build windows --release
fi

if [ "$MODE" != "patch" ]; then
  if [ ! -f "$EXE" ]; then
    echo "未找到 $EXE"
    ls -lah "$RELEASE_DIR" || true
    exit 1
  fi
  echo ">>> 安装目录: $RELEASE_DIR"
  ls -lh "$EXE"
fi

echo ""
if [ "$MODE" = "build" ]; then
  echo "完成：Windows 普通打包"
else
  echo "完成：Shorebird $MODE windows"
fi
