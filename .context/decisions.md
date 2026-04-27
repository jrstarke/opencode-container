# Decisions & Design Choices

## Why separate defaults from project domains?

**Decision**: Keep default domains in `init-firewall.sh` (not in a file), project domains from mounted file.

**Rationale**:
- Defaults are container-level - same for all projects
- Project domains come from whatever workspace is mounted
- Avoids copying files in Dockerfile that get stale

## Why combine defaults + project?

**Decision**: Always combine default domains with project domains.

**Rationale**:
- Projects need npm, Anthropic, etc. by default
- Projects can add their own specific domains
- Single source of truth for what's allowed

## Why not copy allowed-domains in Dockerfile?

**Decision**: Don't copy any domain files in Dockerfile.

**Rationale**:
- Files would get baked into image and go stale
- Workspace mounted at runtime has latest domains
- Can swap projects without rebuilding image

## Why use iptables/ipset?

**Decision**: Use Linux iptables with ipset for firewall.

**Rationale**:
- ipset handles many IPs efficiently
- Can block entire domains at once
- Docker-compatible approach

## Skipped alternatives

- **Cloudflare Magic Transit**: Too expensive
- **Docker network policies**: Not flexible enough
- **ufw**: Doesn't integrate well with Docker