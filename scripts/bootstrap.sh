#!/usr/bin/env bash
# One command to go from this folder to a live agent pipeline on GitHub.
# Run on your Mac, from the agent-sandbox folder:   bash scripts/bootstrap.sh
# Needs: git, gh (brew install gh) logged in with `gh auth login`, and claude (Claude Code CLI).
set -euo pipefail
cd "$(dirname "$0")/.."

REPO_NAME="${REPO_NAME:-agent-sandbox}"

need() { command -v "$1" >/dev/null || { echo "Missing '$1'. $2"; exit 1; }; }
need git "Install Xcode command line tools: xcode-select --install"
need gh "Install with: brew install gh"
need claude "Install Claude Code: npm install -g @anthropic-ai/claude-code"
gh auth status >/dev/null 2>&1 || { echo "Run 'gh auth login' first."; exit 1; }

OWNER=$(gh api user --jq .login)
echo "==> GitHub user: $OWNER, repo: $OWNER/$REPO_NAME"

# 1. Local git repo + first commit
if [ ! -d .git ]; then
  git init -q -b main
  git add .
  git commit -q -m "Initial agent pipeline"
  echo "==> Created local git repo"
fi

# 2. Create the public GitHub repo and push
if gh repo view "$OWNER/$REPO_NAME" >/dev/null 2>&1; then
  echo "==> Repo already exists, pushing"
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$OWNER/$REPO_NAME.git"
  git push -u origin main
else
  gh repo create "$REPO_NAME" --public --source . --push \
    --description "Autonomous coder → reviewer → deploy agent pipeline"
fi

# 3. Repo settings: labels, auto-merge, Pages, branch protection
bash scripts/setup_repo.sh

# 4. Secret: Claude subscription token
if gh secret list | grep -q '^CLAUDE_CODE_OAUTH_TOKEN'; then
  echo "==> CLAUDE_CODE_OAUTH_TOKEN already set"
else
  echo
  echo "==> Step 4/5: Claude subscription token"
  echo "    A browser window will open to log in. When it finishes, copy the token it prints (starts with sk-ant-oat)."
  read -r -p "    Press Enter to run 'claude setup-token'..." _
  claude setup-token
  echo
  read -r -s -p "    Paste the token here and press Enter: " CC_TOKEN; echo
  printf '%s' "$CC_TOKEN" | gh secret set CLAUDE_CODE_OAUTH_TOKEN
  unset CC_TOKEN
fi

# 5. Secret: fine-grained GitHub token for the agents
if gh secret list | grep -q '^AGENT_GH_TOKEN'; then
  echo "==> AGENT_GH_TOKEN already set"
else
  echo
  echo "==> Step 5/5: GitHub token the agents will use"
  echo "    Opening GitHub. Create a fine-grained token with:"
  echo "      - Repository access: Only select repositories → $REPO_NAME"
  echo "      - Permissions: Contents, Issues, Pull requests = Read and write"
  echo "      - Do NOT add Workflows (this is what stops agents editing the pipeline)"
  open "https://github.com/settings/personal-access-tokens/new" 2>/dev/null || true
  read -r -s -p "    Paste the token here and press Enter: " AGENT_TOKEN; echo
  printf '%s' "$AGENT_TOKEN" | gh secret set AGENT_GH_TOKEN
  unset AGENT_TOKEN
fi

# 6. First deploy so production exists before the agents ship anything
gh workflow run deploy.yml >/dev/null 2>&1 || true

echo
echo "✅ Pipeline is live: https://github.com/$OWNER/$REPO_NAME"
echo
echo "Try it now:"
echo "  gh issue create --title 'Add TodoList.rename' --label agent:build \\"
echo "    --body 'Add TodoList.rename(task_id, new_title). Reject blank titles with ValueError, unknown ids with KeyError. Add tests.'"
echo
echo "Then watch:  gh run watch   or   https://github.com/$OWNER/$REPO_NAME/actions"
