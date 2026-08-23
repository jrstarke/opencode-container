#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(pwd)}"

MOUNT_DOCKER_SOCKET=false
ARGS=()
for arg in "$@"; do
  if [ "$arg" = "--mount-docker-socket" ]; then
    MOUNT_DOCKER_SOCKET=true
  else
    ARGS+=("$arg")
  fi
done
set -- "${ARGS[@]}"

GIT_USER_NAME=$(git config --global user.name 2>/dev/null || echo "")
GIT_USER_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

echo "=== Building opencode container ==="
docker build -t opencode-sandbox "$SCRIPT_DIR"

echo "=== Running opencode sandbox ==="
echo "Workspace: $WORKSPACE_DIR"
# opencode-sandbox-claude-config holds the whole ~/.claude dir, but only the
# OAuth credentials in it are actually meant to survive across runs.
# entrypoint.sh re-seeds CLAUDE.md/settings.json/plugins from the image and
# wipes projects/ (memory + session history, which would otherwise bleed
# across different host projects since they all mount to /workspace) on
# every start.
# Persist Google auth token
antigravity_auth_dir="${HOME}/.gemini/antigravity-cli"
mkdir -p "$antigravity_auth_dir"

DOCKER_SOCKET_ARGS=()
if [ "$MOUNT_DOCKER_SOCKET" = "true" ]; then
  echo "Mounting host Docker socket into the sandbox (--mount-docker-socket)"
  DOCKER_SOCKET_ARGS=(--group-add docker -v /var/run/docker.sock:/var/run/docker.sock)
fi

docker run -it --rm \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  --add-host=host.docker.internal:host-gateway \
  -v "$WORKSPACE_DIR":/workspace \
  -v opencode-sandbox-history:/commandhistory \
  -v opencode-sandbox-claude-config:/home/appuser/.claude \
  "${DOCKER_SOCKET_ARGS[@]}" \
  -v "$antigravity_auth_dir":/home/appuser/.gemini/antigravity-cli \
  -e NODE_OPTIONS="--max-old-space-size=4096" \
  -e HOME=/home/appuser \
  -e HOST_WORKSPACE="$WORKSPACE_DIR" \
  -e GIT_USER_NAME="$GIT_USER_NAME" \
  -e GIT_USER_EMAIL="$GIT_USER_EMAIL" \
  -w /workspace \
  opencode-sandbox \
  "$@"
