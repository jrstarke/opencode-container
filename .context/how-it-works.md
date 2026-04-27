# How the Sandbox Works

## Overview

This is a sandboxed OpenCode environment with firewall-based network restrictions.

## Architecture

```
Host Machine
    |
    v (WORKSPACE_DIR mounted to /workspace)
Docker Container
    |
    v (init-firewall.sh runs on startup)
iptables + ipset
    |
    v (only allowed domains can be reached)
```

## Flow

1. `run.sh` builds the Docker image from `/workspace/Dockerfile`
2. Runs container with workspace mounted from host at `/workspace/`
3. Container entrypoint (`entrypoint.sh`) runs `init-firewall.sh`
4. Firewall script:
   - Fetches GitHub IP ranges
   - Combines default domains with project domains from `/workspace/allowed-domains`
   - Resolves domain names to IPs
   - Adds to ipset and configures iptables rules
5. OpenCode starts with restricted network access

## Key Files

- `run.sh` - Build and run script
- `init-firewall.sh` - Firewall configuration
- `entrypoint.sh` - Container entry point
- `Dockerfile` - Container definition