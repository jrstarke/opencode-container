# Project AGENTS.md

This project uses a sandboxed OpenCode setup with firewall-based network restrictions.

## Files

- **`init-firewall.sh`** - Firewall configuration script. Sets up iptables rules to restrict outbound network access to allowed domains only.

- **`allowed-domains.container`** (optional) - Container default allowed domains. Gets loaded first.

- **`/workspace/allowed-domains`** (optional) - Project-specific allowed domains. If this file exists, it's combined with container domains, deduplicated, and loaded into the firewall.

- **Home config** (`~/.config/opencode/`) - Contains base configuration:
  - `AGENTS.md` - Base agent instructions
  - `allowed-domains` - Master allowed domains list

## How It Works

1. `init-firewall.sh` queries `/workspace/allowed-domains` for container default domains
2. Combines with `/workspace/allowed-domains` if it exists (project-specific domains)
3. Deduplicates and removes comments
4. Resolves domain names to IPs and adds them to the `allowed-domains` ipset
5. Restricts all other outbound traffic

## Memory

**File**: `/workspace/.context/memory.md`

Automatically loaded at session start.

## Context Files

Additional notes in `/workspace/.context/`:
- `decisions.md` - Design choices
- `wip.md` - Work in progress
- `running.md` - How to run this project
- `domains.md` - Allowed domains