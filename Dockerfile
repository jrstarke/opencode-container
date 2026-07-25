FROM debian:stable-slim

ARG TARGETARCH=arm64
ARG OPENCODE_VERSION=1.17.13
ARG ASDF_VERSION=0.19.0

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates curl git iptables ipset dnsutils coreutils procps jq bash gosu docker-cli iproute2 libatomic1 golang-go \
  && update-ca-certificates \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Build dependencies for asdf's python plugin (pyenv/python-build compiles
# CPython from source; there's no prebuilt-binary path like nodejs has).
RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
  libsqlite3-dev libncursesw5-dev xz-utils tk-dev libxml2-dev \
  libxmlsec1-dev libffi-dev liblzma-dev \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN ARCH=$(echo "$TARGETARCH" | sed 's/amd64/x64/;s/arm64/arm64/') && \
  curl -L "https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-${ARCH}.tar.gz" -o /tmp/opencode.tar.gz && \
  tar -xzf /tmp/opencode.tar.gz -C /usr/local/bin opencode && \
   chmod +x /usr/local/bin/opencode && \
    # Install Antigravity CLI (latest GitHub release)
    ARCH=$(echo "$TARGETARCH" | sed 's/amd64/x64/;s/arm64/arm64/') && \
      # Download appropriate Antigravity CLI archive based on architecture
      AGY_ASSET="agy_cli_linux_${ARCH}.tar.gz" && \
      curl -L "https://github.com/google-antigravity/antigravity-cli/releases/download/1.1.4/${AGY_ASSET}" -o /tmp/agy.tar.gz && \
      tar -xzf /tmp/agy.tar.gz -C /usr/local/bin antigravity && \
      mv /usr/local/bin/antigravity /usr/local/bin/agy && \
      chmod +x /usr/local/bin/agy && \
       rm /tmp/agy.tar.gz && rm /tmp/opencode.tar.gz

# Install qemu for non-native binaries
RUN apt-get update && apt-get install -y --no-install-recommends qemu-user-static && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /home/appuser && useradd -m -s /bin/bash appuser || true
RUN chown -R appuser:appuser /home/appuser
RUN groupadd -g 991 docker || true
RUN usermod -aG docker appuser || true

# Install Claude Code CLI via official installer, as appuser, so it lands under
# /home/appuser/.local/bin and the install-method bookkeeping `claude doctor` checks
# for matches the user the entrypoint actually runs claude as.
RUN gosu appuser bash -lc "curl -fsSL https://claude.ai/install.sh | bash"

RUN ARCH=$(echo "$TARGETARCH" | sed 's/amd64/amd64/;s/arm64/arm64/') && \
  curl -L "https://github.com/asdf-vm/asdf/releases/download/v${ASDF_VERSION}/asdf-v${ASDF_VERSION}-linux-${ARCH}.tar.gz" -o /tmp/asdf.tar.gz && \
  tar -xzf /tmp/asdf.tar.gz -C /tmp && \
  mv /tmp/asdf /usr/local/bin/asdf && \
  chmod +x /usr/local/bin/asdf && \
  rm /tmp/asdf.tar.gz

RUN mkdir /commandhistory && touch /commandhistory/.bash_history && chown -R appuser /commandhistory || true

RUN mkdir -p /home/appuser/.asdf/shims && chown -R appuser:appuser /home/appuser/.asdf
RUN mkdir -p /home/appuser/.gemini/config && chown -R appuser:appuser /home/appuser/.gemini
RUN mkdir -p /home/appuser/.claude/config && chown -R appuser:appuser /home/appuser/.claude

# Pre-install node (latest LTS) and python (latest stable 3.x) via asdf, and
# pin them as appuser's global default via `asdf set --home` (writes
# ~/.tool-versions). Versions resolved at the time this was written:
#   node   -> `asdf latest nodejs lts`
#   python -> newest non-experimental 3.x from `asdf list all python`
ARG NODE_VERSION=24.18.0
ARG PYTHON_VERSION=3.14.6
RUN gosu appuser bash -lc "\
  export PATH=/usr/local/bin:\$PATH && \
  asdf plugin add nodejs && \
  asdf plugin add python && \
  asdf install nodejs ${NODE_VERSION} && \
  asdf install python ${PYTHON_VERSION} && \
  asdf set --home nodejs ${NODE_VERSION} && \
  asdf set --home python ${PYTHON_VERSION} \
"

# Install OpenWolf (context-management middleware for coding agents,
# https://github.com/cytostack/openwolf) globally into appuser's asdf-managed
# node, so `openwolf` is on PATH via the asdf shims already on PATH (below).
RUN gosu appuser bash -lc "\
  export PATH=/home/appuser/.asdf/shims:\$PATH && \
  npm install -g openwolf \
"

# Pre-accept onboarding and the /workspace trust dialog. This container runs
# with --rm and no volume for ~/.claude, so without this the first-run wizard
# and trust prompt would reappear on every run. hasCompletedOnboarding /
# hasTrustDialogAccepted are undocumented internal state keys, not a public
# config surface, but stable enough to rely on given the binary is pinned
# above via DISABLE_UPDATES.
RUN echo '{"hasCompletedOnboarding": true, "projects": {"/workspace": {"hasTrustDialogAccepted": true, "projectOnboardingSeenCount": 1}}}' > /home/appuser/.claude.json && \
  chown appuser:appuser /home/appuser/.claude.json

# Best-effort attempt to skip the Bypass Permissions mode confirmation dialog
# too (untested against a real top-level session; needs verification).
RUN echo '{"skipDangerousModePermissionPrompt": true, "theme": "light"}' > /home/appuser/.claude/settings.json && \
  chown appuser:appuser /home/appuser/.claude/settings.json

# Install the Superpowers plugin for Claude Code, mirroring the opencode.json
# declarative "plugin" entry. Docs describe a CLAUDE_CODE_PLUGIN_SEED_DIR /
# CLAUDE_CODE_PLUGIN_CACHE_DIR container-seeding mechanism for this, but it
# did not actually get picked up at runtime when tested against this image
# (v2.1.220) — `claude plugin list` came back empty despite a correctly
# populated seed dir. Installing straight into the default ~/.claude/plugins
# location at build time works and is verified to persist and load normally.
RUN gosu appuser bash -lc "\
  export PATH=/home/appuser/.local/bin:\$PATH && \
  claude plugin marketplace add obra/superpowers-marketplace && \
  claude plugin install superpowers@superpowers-marketplace \
"

ENV HOST_WORKSPACE=/workspace
ENV PATH=/home/appuser/.local/bin:/home/appuser/.asdf/shims:$PATH
# Claude Code is distributed via this image, not its own updater; block all
# update paths (background auto-update and manual `claude update`/`install`)
# so the binary installed at build time stays immutable at runtime.
ENV DISABLE_UPDATES=1

COPY init-firewall.sh /usr/local/bin/init-firewall.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY AGENTS.md.container /home/appuser/.config/opencode/AGENTS.md
COPY AGENTS.md.container /home/appuser/.claude/CLAUDE.md
COPY opencode.json.container /home/appuser/.config/opencode/opencode.json
RUN chmod 755 /usr/local/bin/init-firewall.sh /usr/local/bin/entrypoint.sh
RUN chown appuser:appuser /home/appuser/.claude/CLAUDE.md

RUN mkdir -p /workspace && chown -R appuser /workspace /commandhistory

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]