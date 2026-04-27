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

## Available Skills

- `context-save` - Located at `/home/appuser/.config/opencode/skills/context-save`

**Note:** Skills require explicit path in config:
```json
"skills": {
  "paths": ["/home/appuser/.config/opencode/skills"]
}
```