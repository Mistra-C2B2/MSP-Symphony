#!/bin/bash
set -e

CERT="/workspace/frontend/ssl/server.crt"
KEY="/workspace/frontend/ssl/server.key"

cd /workspace/frontend

# Check if certificate and key exist
if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
  echo "SSL certificate or key not found. Generating..."
  npm run generate-cert
fi

npm install

PROXY_TARGET=local ng serve --ssl --host 0.0.0.0
