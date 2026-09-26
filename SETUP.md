# Agent pipeline: setup

Three agents run on GitHub Actions and use your Claude Pro/Max subscription (no API key):

| Agent | Workflow | Trigger | Can do |
|---|---|---|---|
| Coder | `coder-agent.yml` | Issue gets label `agent:build` | Edit code, run tests, push an `agent/*` branch, open a PR, enable auto-merge |
| Reviewer | `reviewer-agent.yml` | PR from an `agent/*` branch opened/updated | Read code, run tests, write a verdict. Cannot change code |
| Coder (fix mode) | `reviewer-agent.yml` → `fix` job | Reviewer said `REQUEST_CHANGES` | Push fixes to the same PR (max 3 rounds, then `needs-human`) |
| Deploy | `deploy.yml` | Push to `main` | Test → deploy to GitHub Pages → smoke test → auto-revert if unhealthy |

A PR auto-merges only when **both** required checks are green: `ci` (tests + lint) and `agent-review` (guard + reviewer approval).

## 1. Create the repo and push

```bash
cd agent-sandbox
git init -b main && git add . && git commit -m "Initial agent pipeline"
gh repo create agent-sandbox --public --source . --push
```

Use **public**: branch protection is free on public repos. For a private repo it needs GitHub Pro.

## 2. Secrets

**`CLAUDE_CODE_OAUTH_TOKEN`**: your subscription token.
```bash
claude setup-token          # on your Mac, in a terminal; copy the token it prints
gh secret set CLAUDE_CODE_OAUTH_TOKEN
```

**`AGENT_GH_TOKEN`**: a fine-grained personal access token the agents use for git and GitHub.
GitHub → Settings → Developer settings → Fine-grained tokens → Generate:
- Repository access: **only** `agent-sandbox`
- Permissions: Contents **Read & write**, Pull requests **Read & write**, Issues **Read & write** (Metadata read is automatic)
- Do **not** grant Workflows: then no agent can push changes to `.github/workflows/`, even if it tries.

```bash
gh secret set AGENT_GH_TOKEN
```

Why a PAT and not the built-in `GITHUB_TOKEN`: GitHub doesn't start other workflows from events made with `GITHUB_TOKEN`, so the coder's PR would never trigger CI or the reviewer.

## 3. Repo settings

```bash
bash scripts/setup_repo.sh
```
This creates the labels, turns on auto-merge (squash only), enables Pages via Actions, and protects `main` with the `ci` + `agent-review` required checks.

## 4. Try it

1. Open an issue, e.g. *"Add `TodoList.rename(task_id, new_title)` that rejects blank titles and raises KeyError for unknown ids."*
2. Add the label `agent:build`.
3. Watch it: coder comment on the issue → PR appears → CI + reviewer run → review comment → auto-merge → Deploy workflow → your Pages URL shows the new commit.

## Safety rails built in

- **Guard job**: a PR touching `.github/`, `CLAUDE.md` or `scripts/setup_repo.sh` is blocked, labeled `needs-human`, and auto-merge is turned off.
- **Reviewer prompts are read from `main`**, so a PR can't rewrite its own reviewer.
- **Reviewer is read-only**: its tools only allow writing inside `.agent/`, and a check fails the run if it touched anything else.
- **Fix loop capped** at 3 rounds, then a human takes over.
- **Turn limits and timeouts** on every agent (`--max-turns`, `timeout-minutes`).
- **Auto-rollback** reverts a commit that fails the production smoke test, opens a `needs-human` issue, and never reverts a revert.
- Only people with write access can trigger the agents; bots are rejected by the action.

## Cost and limits

Agent runs count against your Claude subscription's usage limits, the same pool as your own Claude Code use. A busy day of agent PRs can use up your quota, so start with a few issues. GitHub Actions minutes are free on public repos.

## Moving to a real project later

Copy `.github/`, `CLAUDE.md` and `scripts/setup_repo.sh`, then edit `CLAUDE.md` (commands and rules), `OFF_LIMITS` in `reviewer-agent.yml` (e.g. add `migrations/`, `auth/`, `payments/`), and replace the Pages deploy/smoke steps with your real deploy and health check.
