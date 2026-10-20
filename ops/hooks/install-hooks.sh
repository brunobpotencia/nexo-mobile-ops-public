#!/bin/bash
# Install git hooks for the repo. Run once per clone.
HOOKS_DIR=$(git rev-parse --git-dir)/hooks
cp ops/hooks/pre-push "$HOOKS_DIR/pre-push"
chmod +x "$HOOKS_DIR/pre-push"
echo "pre-push hook installed"
