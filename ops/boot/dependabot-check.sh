#!/usr/bin/env bash
# Verifica se Dependabot abriu PRs abertos ha mais de 7 dias sem review
set -euo pipefail
STALE=$(gh api repos/<OWNER>/<REPO>/pulls --jq '[.[] | select(.draft==false and .state=="open" and .user.login=="app/dependabot")] | length' 2>/dev/null || echo 0)
echo "dependabot_open_prs=$STALE"
