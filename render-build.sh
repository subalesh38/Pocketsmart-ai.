#!/usr/bin/env bash
# exit on error
set -o errexit

echo "=== Installing Python dependencies ==="
pip install -r backend/requirements.txt

echo "=== Checking frontend assets ==="
if command -v npm &> /dev/null; then
  echo "Node & npm detected. Building frontend assets..."
  npm ci || npm install
  npm run build
elif [ -d "dist" ]; then
  echo "Using pre-built frontend assets in dist/ directory."
else
  echo "Installing nodeenv to build frontend..."
  pip install nodeenv
  nodeenv -p
  npm install
  npm run build
fi

echo "=== Build finished successfully ==="
