# Branch Protection Policy

## Status
- Rulesets via API: blocked on free plan (403). Requires Pro or public repo.
- Workaround: enforce via branch rules in UI or PAT with admin scope.

## Rules to apply (UI: Settings > Branches > Branch protection rule)
- Require a pull request before merging on `main` and `meridian-v2`
- Require at least 1 approving review
- Dismiss stale pull request approvals when new commits are pushed
- Require status checks to pass before merging (CI: validate.sh)
- Do not allow bypassing the above settings
- Restrict who can push to matching branches: <OWNER> only

## Why
- Prevents direct push to main without review
- Ensures CI (validate.sh) gates every merge
- Limits blast radius of a leaked token or compromised session
