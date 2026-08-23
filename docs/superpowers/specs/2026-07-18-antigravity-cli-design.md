# Antigravity CLI Integration Design

## Overview
Add the Antigravity CLI (`agy`) to the container and make the entrypoint capable of invoking either `opencode` or `agy` based on the first argument.

## Dockerfile modifications
```Dockerfile
# Existing opencode download (lines 12‑15) remain unchanged

# Install Antigravity CLI (latest GitHub release)
RUN ARCH=$(echo "$TARGETARCH" | sed 's/amd64/x64/;s/arm64/arm64/') && \
    curl -L "https://github.com/antigravity/cli/releases/latest/download/antigravity-linux-${ARCH}.tar.gz" -o /tmp/agy.tar.gz && \
    tar -xzf /tmp/agy.tar.gz -C /usr/local/bin agy && \
    chmod +x /usr/local/bin/agy && \
    rm /tmp/agy.tar.gz
```
- Uses the same `ARCH` variable logic as opencode.
- Places the binary as `/usr/local/bin/agy`.

## Entrypoint script changes (`/usr/local/bin/entrypoint.sh`)
```bash
#!/usr/bin/env bash
set -e

# If the first argument is a known tool, exec it; otherwise default to opencode
case "$1" in
  opencode)
    exec /usr/local/bin/opencode "${@:2}"
    ;;
  agy)
    exec /usr/local/bin/agy "${@:2}"
    ;;
  *)
    # No recognized tool; default to opencode with original args
    exec /usr/local/bin/opencode "$@"
    ;;
esac
```
- Shifts arguments so the called tool receives only its own parameters.
- Preserves current behaviour when no argument or unknown argument is supplied.

## Documentation
Add a short entry in the project docs explaining the new entrypoint usage:
```
# Usage
$ docker run <image> opencode <opencode-args>
$ docker run <image> agy <agy-args>
```

## Spec location
`docs/superpowers/specs/2026-07-18-antigravity-cli-design.md`

---
*Design approved and ready for implementation.*
