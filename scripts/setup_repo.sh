#!/usr/bin/env bash
# One-time repo setup for the agent pipeline. Run from the repo root after the first push:
#   bash scripts/setup_repo.sh
# Needs: gh CLI logged in as the repo owner (gh auth login).
set -euo pipefail

REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
echo "Configuring $REPO"

echo "→ Labels"
gh label create "agent:build" --color 5319E7 --description "Coder agent: implement this issue" --force
gh label create "needs-human" --color D93F0B --description "Agents stopped; a human must decide" --force

echo "→ Allow auto-merge, squash only, delete merged branches"
gh api -X PATCH "repos/$REPO" \
  -F allow_auto_merge=true -F allow_squash_merge=true \
  -F allow_merge_commit=false -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true >/dev/null

echo "→ GitHub Pages via Actions (the sandbox's 'production')"
gh api -X POST "repos/$REPO/pages" -f build_type=workflow >/dev/null 2>&1 \
  || gh api -X PUT "repos/$REPO/pages" -f build_type=workflow >/dev/null

echo "→ Branch protection on main: require the ci and agent-review checks"
gh api -X PUT "repos/$REPO/branches/main/protection" --input - >/dev/null <<'JSON'
{
  "required_status_checks": { "strict": false, "contexts": ["ci", "agent-review"] },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON

echo
echo "Done. Remaining manual step: add the two repo secrets (see SETUP.md):"
echo "  gh secret set CLAUDE_CODE_OAUTH_TOKEN"
echo "  gh secret set AGENT_GH_TOKEN"
