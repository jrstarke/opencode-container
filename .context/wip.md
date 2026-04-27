# Work In Progress

## Completed

- [x] Fix WORKSPACE_DIR to default to pwd instead of script directory
- [x] Remove vscode/marketplace domains from defaults
- [x] Combine defaults + project domains (not exclusive)
- [x] Split context into multiple files (decisions, wip, running, domains)
- [x] Update AGENTS.md.container with context guidelines

## Current Issues

- Need to verify firewall actually blocks unwanted domains

## Things to Test

- Verify all blocked domains are actually blocked
- Test with multiple projects

## Future Ideas

- Add model configuration to container config
- Add custom tools/install scripts to container
- Pre-install common dev tools
- Add ssh/git access through firewall