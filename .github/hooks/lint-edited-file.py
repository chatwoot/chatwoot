#!/usr/bin/env python3
"""PostToolUse hook: run rubocop/eslint on edited files automatically."""
import json
import os
import subprocess
import sys


def main():
    data = json.load(sys.stdin)

    if data.get("tool_name") not in (
        "replace_string_in_file",
        "create_file",
        "multi_replace_string_in_file",
    ):
        return

    inp = data.get("tool_input", {})
    path = inp.get("filePath", "")
    if not path:
        replacements = inp.get("replacements", [])
        if replacements:
            path = replacements[0].get("filePath", "")
    if not path or not os.path.isfile(path):
        return

    repo = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    if not path.startswith(repo + "/"):
        return

    ext = os.path.splitext(path)[1]
    errors = ""

    if ext == ".rb":
        r = subprocess.run(
            'eval "$(rbenv init - 2>/dev/null)" && bundle exec rubocop '
            + f'"{path}" --format simple --no-autocorrect',
            shell=True,
            capture_output=True,
            text=True,
            cwd=repo,
        )
        if r.returncode != 0:
            errors = (r.stdout + r.stderr).strip()

    elif ext in (".vue", ".js", ".ts", ".tsx", ".jsx"):
        r = subprocess.run(
            ["npx", "--no-install", "eslint", path],
            capture_output=True,
            text=True,
            cwd=repo,
        )
        if r.returncode != 0:
            errors = (r.stdout + r.stderr).strip()

    if errors:
        print(
            json.dumps(
                {
                    "hookSpecificOutput": {
                        "hookEventName": "PostToolUse",
                        "additionalContext": f"Lint errors in {os.path.basename(path)}:\n{errors}",
                    }
                }
            )
        )


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
