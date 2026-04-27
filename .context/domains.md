# Allowed Domains

## Default Domains

These are hardcoded in `init-firewall.sh` under `DEFAULT_DOMAINS`:

- `registry.npmjs.org` - npm package registry
- `api.anthropic.com` - Anthropic API
- `opencode.ai` - OpenCode
- `sentry.io` - Error tracking

Plus GitHub IP ranges (fetched from `api.github.com/meta`).

## Project Domains

Add project-specific domains in `/workspace/allowed-domains`:

```
example.com
api.example.com
```

Format: one domain per line, lines starting with `#` are comments.

## Combining

At runtime, defaults + project domains are:
1. Combined into one list
2. Deduplicated (`sort -u`)
3. Resolved to IP addresses via DNS
4. Added to the `allowed-domains` ipset

## Adding New Domains

1. Edit project's `allowed-domains` file
2. Rebuild container (or restart to pick up changes)
3. Firewall will resolve and allow the new domains