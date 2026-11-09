#!/usr/bin/env python3
"""Checks for the "ai-service promote" workflow (DEV-Johnstocker/chatwoot#39, refs #1).

  promote.py check [SHA]

Picks the commit to promote (SHA, or the newest develop commit whose `staging`
status is success), refuses it when it should not reach production, and writes
`sha` and `prev` to $GITHUB_OUTPUT plus a summary of what would ship to
$GITHUB_STEP_SUMMARY. `prev` is the commit on the `production` branch now
(empty before the first promote).

Run inside a full clone (fetch-depth 0) with origin/develop and, once it
exists, origin/production fetched. Needs GH_TOKEN and REPO for the status API.
"""

import os
import re
import subprocess
import sys

SHA = re.compile(r"^[0-9a-f]{7,40}$")
# Knowledge-base schema files. A range that changes one needs a backup first,
# which only /deploy does today (AGENTS.md §5).
SCHEMA = re.compile(r"^ai-service/internal/knowledge/schema[^/]*\.sql$")
CANDIDATES = 50


def valid_sha(value):
    return bool(SHA.match(value or ""))


def pick(candidates, staging_state):
    """The first (newest) candidate whose staging status is success."""
    for sha in candidates:
        if staging_state(sha) == "success":
            return sha
    return None


def refusals(sha, prev, on_develop, after_prev, staging, changed):
    """Reasons not to promote sha; empty when it may go to production."""
    reasons = []
    if not on_develop:
        reasons.append(f"{sha[:10]} is not on develop")
    if staging != "success":
        reasons.append(f"staging status is {staging or 'missing'}; promote only a commit that passed staging")
    if prev and sha != prev and not after_prev:
        reasons.append(f"{sha[:10]} is older than production ({prev[:10]}); that is a rollback, not a promote")
    schema = [f for f in changed if SCHEMA.match(f)]
    if schema:
        reasons.append("the range changes the database schema (" + ", ".join(schema)
                       + "); run /deploy, which takes a backup first")
    return reasons


def git(*args, check=True):
    return subprocess.run(["git", *args], capture_output=True, text=True, check=check).stdout.strip()


def is_ancestor(older, newer):
    return subprocess.run(["git", "merge-base", "--is-ancestor", older, newer]).returncode == 0


def staging_state(sha):
    repo = os.environ["REPO"]
    out = subprocess.run(
        ["gh", "api", f"repos/{repo}/commits/{sha}/status",
         "--jq", '.statuses[] | select(.context == "staging") | .state'],
        capture_output=True, text=True)
    lines = out.stdout.split()
    return lines[0] if out.returncode == 0 and lines else None


def append(path_var, text):
    path = os.environ.get(path_var)
    if path:
        with open(path, "a", encoding="utf-8") as f:
            f.write(text)
    else:
        print(text, end="")


def check(requested):
    prev = git("rev-parse", "--verify", "--quiet", "origin/production^{commit}", check=False) or None
    if requested:
        if not valid_sha(requested):
            sys.exit(f"refused: {requested!r} is not a commit SHA")
        sha = git("rev-parse", "--verify", "--quiet", requested + "^{commit}", check=False)
        if not sha:
            sys.exit(f"refused: commit {requested} not found")
    else:
        candidates = git("rev-list", "--first-parent", f"-n{CANDIDATES}", "origin/develop").split()
        sha = pick(candidates, staging_state)
        if not sha:
            sys.exit(f"refused: none of the last {CANDIDATES} develop commits has a green staging status")

    changed = git("diff", "--name-only", prev, sha).splitlines() if prev else []
    reasons = refusals(sha, prev, is_ancestor(sha, "origin/develop"),
                       bool(prev) and is_ancestor(prev, sha), staging_state(sha), changed)

    log = git("log", "--first-parent", "--format=- %h %s", f"{prev}..{sha}") if prev else "(first promote)"
    summary = (f"### Promote to production\n\n- commit: `{sha}`\n- production now: `{prev or 'none'}`\n\n"
               f"Ships:\n\n{log or '(nothing new: redeploy of the same commit)'}\n\n")
    if reasons:
        summary += "**Refused:**\n\n" + "".join(f"- {r}\n" for r in reasons)
    append("GITHUB_STEP_SUMMARY", summary)
    if reasons:
        sys.exit("refused: " + "; ".join(reasons))
    append("GITHUB_OUTPUT", f"sha={sha}\nprev={prev or ''}\n")


def main(argv):
    if not argv or argv[0] != "check" or len(argv) > 2:
        sys.exit("usage: promote.py check [SHA]")
    check(argv[1] if len(argv) == 2 else "")


if __name__ == "__main__":
    main(sys.argv[1:])
