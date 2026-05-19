FROM debian:stable-slim

ARG TARGETARCH
ARG OPENCODE_VERSION=1.15.3
ARG ASDF_VERSION=0.19.0

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates curl git iptables ipset dnsutils coreutils procps jq bash gosu docker-cli iproute2 libatomic1 openssh-client \
  && update-ca-certificates \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -L "https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-${TARGETARCH}.tar.gz" -o /tmp/opencode.tar.gz && \
  tar -xzf /tmp/opencode.tar.gz -C /usr/local/bin opencode && \
  chmod +x /usr/local/bin/opencode && \
  rm /tmp/opencode.tar.gz

RUN mkdir -p /home/appuser && useradd -m -s /bin/bash appuser || true
RUN chown -R appuser:appuser /home/appuser
RUN groupadd -g 991 docker || true
RUN usermod -aG docker appuser || true
RUN curl -L "https://github.com/asdf-vm/asdf/releases/download/v${ASDF_VERSION}/asdf-v${ASDF_VERSION}-linux-${TARGETARCH}.tar.gz" -o /tmp/asdf.tar.gz && \
  tar -xzf /tmp/asdf.tar.gz -C /tmp && \
  mv /tmp/asdf /usr/local/bin/asdf && \
  chmod +x /usr/local/bin/asdf && \
  rm /tmp/asdf.tar.gz

RUN mkdir /commandhistory && touch /commandhistory/.bash_history && chown -R appuser /commandhistory || true

RUN mkdir -p /home/appuser/.asdf/shims && chown -R appuser:appuser /home/appuser/.asdf

ENV HOST_WORKSPACE=/workspace
ENV PATH=/home/appuser/.asdf/shims:$PATH

COPY init-firewall.sh /usr/local/bin/init-firewall.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY AGENTS.md.container /home/appuser/.config/opencode/AGENTS.md
COPY opencode.json.container /home/appuser/.config/opencode/opencode.json
RUN chmod 755 /usr/local/bin/init-firewall.sh /usr/local/bin/entrypoint.sh

RUN mkdir -p /workspace && chown -R appuser /workspace /commandhistory

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]