#!/usr/bin/env bash
set -euo pipefail

if ! command -v gsutil >/dev/null 2>&1; then
  echo "gsutil が見つかりません。Google Cloud SDK をインストールしてください。" >&2
  exit 1
fi

BUCKET="${1:-${BUCKET:-}}"
if [[ -z "${BUCKET}" ]]; then
  echo "Usage: $0 <bucket>" >&2
  echo "例: $0 cocoshibaapp.appspot.com" >&2
  echo "" >&2
  echo "または環境変数で指定: BUCKET=cocoshibaapp.appspot.com $0" >&2
  exit 1
fi

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Setting CORS for: gs://${BUCKET}"
gsutil cors set "${ROOT_DIR}/storage_cors.json" "gs://${BUCKET}"
echo "Done."

