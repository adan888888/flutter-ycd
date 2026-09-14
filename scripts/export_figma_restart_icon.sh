#!/usr/bin/env bash
# Export Figma node 28489:9317 (restart dialog icon) into Flutter assets.
# Requires a valid FIGMA_API_KEY in ~/.cursor/mcp.json or the environment.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/assets/images/figma_review_dialog/restart_state.png"
FILE_KEY="UA8BxQOUWmJ7qkYTX4qYvi"
NODE_ID="28489:9317"

if [[ -z "${FIGMA_API_KEY:-}" ]]; then
  FIGMA_API_KEY="$(python3 - <<'PY'
import json, pathlib
cfg = json.loads(pathlib.Path.home().joinpath(".cursor/mcp.json").read_text())
print(cfg["mcpServers"]["figma-developer-mcp"]["env"]["FIGMA_API_KEY"])
PY
)"
fi

ENCODED_NODE="${NODE_ID//:/%3A}"
IMAGES_JSON="$(curl -sS -H "X-Figma-Token: $FIGMA_API_KEY" \
  "https://api.figma.com/v1/images/${FILE_KEY}?ids=${ENCODED_NODE}&format=png&scale=2")"

URL="$(python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('images',{}).get('${NODE_ID}',''))" <<<"$IMAGES_JSON")"
if [[ -z "$URL" || "$URL" == "None" ]]; then
  echo "Figma export failed: $IMAGES_JSON" >&2
  exit 1
fi

curl -sSL "$URL" -o "$OUT"
echo "Saved $OUT"
