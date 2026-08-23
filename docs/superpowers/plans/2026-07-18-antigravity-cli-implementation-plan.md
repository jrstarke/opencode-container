# Antigravity CLI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the Antigravity CLI (`agy`) to the container image and enable the entrypoint to invoke either `opencode` or `agy` based on the first argument.

**Architecture:** Extend the Dockerfile to download the latest Antigravity CLI binary from GitHub and place it at `/usr/local/bin/agy`. Modify the existing entrypoint script to dispatch to the appropriate binary.

**Tech Stack:** Docker, Bash, curl.

## Global Constraints

- Use same `ARCH` logic as existing opencode download.
- Preserve existing entrypoint default behavior when no recognized argument is given.
- Keep image size minimal; clean up temporary files.

---

### Task 1: Add Antigravity CLI download to Dockerfile

**Files:**
- Modify: `Dockerfile` (add new RUN command after existing opencode download).

**Interfaces:**
- Consumes: `TARGETARCH` environment variable.
- Produces: `/usr/local/bin/agy` binary.

- [ ] **Step 1: Insert Dockerfile snippet**

```Dockerfile
# Install Antigravity CLI (latest GitHub release)
RUN ARCH=$(echo "$TARGETARCH" | sed 's/amd64/x64/;s/arm64/arm64/') && \
    curl -L "https://github.com/antigravity/cli/releases/latest/download/antigravity-linux-${ARCH}.tar.gz" -o /tmp/agy.tar.gz && \
    tar -xzf /tmp/agy.tar.gz -C /usr/local/bin agy && \
    chmod +x /usr/local/bin/agy && \
    rm /tmp/agy.tar.gz
```

- [ ] **Step 2: Build Docker image and verify binary**

Run:
```bash
docker build -t antigravity-test .
```
Then test:
```bash
docker run --rm antigravity-test which agy
```
Expected output: `/usr/local/bin/agy`

- [ ] **Step 3: Commit changes**
```bash
git add Dockerfile
git commit -m "feat: add Antigravity CLI download to Dockerfile"
```

### Task 2: Update entrypoint script to dispatch

**Files:**
- Modify: `/usr/local/bin/entrypoint.sh` (replace or extend existing case logic).

**Interfaces:**
- Consumes: first CLI argument.
- Produces: exec of either `/usr/local/bin/opencode` or `/usr/local/bin/agy`.

- [ ] **Step 1: Insert case statement**

```bash
#!/usr/bin/env bash
set -e

case "$1" in
  opencode)
    exec /usr/local/bin/opencode "${@:2}"
    ;;
  agy)
    exec /usr/local/bin/agy "${@:2}"
    ;;
  *)
    # Default to opencode when no known tool is specified
    exec /usr/local/bin/opencode "$@"
    ;;
esac
```

- [ ] **Step 2: Build and test dispatch**

```bash
docker build -t antigravity-test .
# Test opencode default
docker run --rm antigravity-test opencode --help
# Test agy command
docker run --rm antigravity-test agy --version
```
Expected both commands to succeed.

- [ ] **Step 3: Commit changes**
```bash
git add entrypoint.sh
git commit -m "feat: entrypoint dispatch to opencode or agy"
```

---

**Plan complete.**