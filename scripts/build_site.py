"""Builds the static 'production' page that deploy.yml publishes to GitHub Pages."""

from __future__ import annotations

import html
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from app import __version__  # noqa: E402


def git_sha() -> str:
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, text=True, stderr=subprocess.DEVNULL
        ).strip()
    except Exception:
        return "unknown"


def main() -> None:
    out = ROOT / "site"
    out.mkdir(exist_ok=True)
    sha = git_sha()
    (out / "index.html").write_text(
        f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>Agent Sandbox</title></head>
<body style="font-family:system-ui;max-width:40rem;margin:4rem auto;padding:0 1rem">
<h1>Agent Sandbox</h1>
<p>Version <strong id="version">{html.escape(__version__)}</strong>,
commit <code id="sha">{html.escape(sha)}</code>.</p>
<p>Shipped by the coder, reviewer and deploy agents.</p>
</body></html>
""",
        encoding="utf-8",
    )
    (out / "health.txt").write_text(f"ok {__version__} {sha}\n", encoding="utf-8")
    print(f"built site/ for {__version__} ({sha})")


if __name__ == "__main__":
    main()
