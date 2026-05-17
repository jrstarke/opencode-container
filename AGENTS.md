# OpenCode Sandbox - Project Context

This is the bootstrap project for the OpenCode sandbox container.

## Bootstrap vs Workspace

When modifying sandbox configuration:
- **Edit files in `/workspace/`** - these get bootstrapped into the Docker image
- **Dockerfile copies them to** `/home/appuser/.config/` for runtime

Key bootstrap mappings:
- `opencode.json.container` → `/home/appuser/.config/opencode/opencode.json`
- `AGENTS.md.container` → `/home/appuser/.config/opencode/AGENTS.md`
- `skills/` → `/home/appuser/.config/opencode/skills/`
- `scripts/` → `/home/appuser/scripts/`

## Testing Changes

Rebuild the container to test changes:
```bash
./run.sh
```

## Git Configuration

`run.sh` automatically collects `user.name` and `user.email` from the host's git global config and passes them to the container via environment variables. The entrypoint configures git for the appuser inside the container.

## Available Skills

Skills are defined in `/home/appuser/.cache/opencode/packages/superpowers@git+https:/github.com/obra/superpowers.git/node_modules/superpowers/skills/`