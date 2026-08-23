#!/usr/bin/env bash
set -e
# Build image first if not built
docker build -t claude-test .
# Run claude help to verify binary works
docker run --rm claude-test claude --help > /dev/null
