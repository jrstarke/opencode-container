#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(pwd)}"

GIT_USER_NAME=$(git config --global user.name 2>/dev/null || echo "")
GIT_USER_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

echo "=== Building opencode container ==="
docker build -t opencode-sandbox "$SCRIPT_DIR"

echo "=== Running opencode sandbox ==="
echo "Workspace: $WORKSPACE_DIR"
# Persist Google auth token
antigravity_auth_dir="${HOME}/.gemini/antigravity-cli"
mkdir -p "$antigravity_auth_dir"

docker run -it --rm \
  --group-add docker \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -v "$WORKSPACE_DIR":/workspace \
  -v opencode-sandbox-history:/commandhistory \
  -v opencode-sandbox-claude-config:/home/appuser/.claude \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$antigravity_auth_dir":/home/appuser/.gemini/antigravity-cli \
  -e NODE_OPTIONS="--max-old-space-size=4096" \
  -e HOME=/home/appuser \
  -e HOST_WORKSPACE="$WORKSPACE_DIR" \
  -e GIT_USER_NAME="$GIT_USER_NAME" \
  -e GIT_USER_EMAIL="$GIT_USER_EMAIL" \
  -w /workspace \
  opencode-sandbox \
  "$@"