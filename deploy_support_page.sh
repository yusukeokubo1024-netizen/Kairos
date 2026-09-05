#!/bin/bash
# Deploys public/ to Firebase Hosting with the real Gemini API key substituted
# into index.html — the key lives only in secrets/gemini_api_key.txt (git-
# ignored) and is never written back to the tracked file, so it can't
# accidentally get committed.
set -euo pipefail
cd "$(dirname "$0")"

KEY_FILE="secrets/gemini_api_key.txt"
if [ ! -f "$KEY_FILE" ]; then
  echo "Missing $KEY_FILE — put the Gemini API key there (one line, no quotes) first."
  exit 1
fi
KEY=$(cat "$KEY_FILE")

cp public/index.html public/index.html.bak
trap 'mv public/index.html.bak public/index.html' EXIT

sed -i "s/const GEMINI_API_KEY = 'YOUR_GEMINI_API_KEY_HERE';/const GEMINI_API_KEY = '$KEY';/" public/index.html

firebase deploy --only hosting
