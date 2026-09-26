# Project rules (read by every agent on every run)

## What this repo is
A sandbox for an autonomous coder → reviewer → deploy pipeline. The app is a tiny Python todo library in `app/`.

## Commands
- Install dev deps: `pip install -r requirements-dev.txt`
- Tests: `pytest -q`
- Lint + format check: `ruff check . && ruff format --check .`
- Auto-format: `ruff format .`

## Code rules
- Python 3.11, type hints on public functions, no new runtime dependencies without the issue asking for them.
- Every behaviour change comes with a test in `tests/`.
- Keep changes scoped to the issue. No drive-by refactors.

## Off-limits for agents
Agents must never modify these paths. The pipeline blocks PRs that touch them and hands them to a human:
- `.github/` (workflows and agent prompts)
- `scripts/setup_repo.sh`, `scripts/bootstrap.sh`
- `CLAUDE.md`
