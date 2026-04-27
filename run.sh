#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(pwd)}"

echo "=== Building opencode container ==="
docker build -t opencode-sandbox "$SCRIPT_DIR"

echo "=== Running opencode sandbox ==="
echo "Workspace: $WORKSPACE_DIR"
docker run -it --rm \
  --group-add docker \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -v "$WORKSPACE_DIR":/workspace \
  -v opencode-sandbox-history:/commandhistory \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e NODE_OPTIONS="--max-old-space-size=4096" \
  -e HOME=/home/appuser \
  -e HOST_WORKSPACE="$WORKSPACE_DIR" \
  -w /workspace \
  opencode-sandbox \
  /usr/local/bin/opencode