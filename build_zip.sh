#!/usr/bin/env bash
set -e
find . -name ".DS_Store" -delete
rm -f NacionTV.zip
zip -r NacionTV.zip . \
  -x "*.git*" -x "*.DS_Store" -x "out/*" -x "*.zip" -x "working-File/*"
echo "Built: NacionTV.zip"
