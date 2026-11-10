#!/usr/bin/env python3
"""Checks for the "ai-service promote" workflow (DEV-Johnstocker/chatwoot#39, refs #1).

  promote.py check [--auto] [SHA]

Picks the commit to promote (SHA, or the newest develop commit whose `staging`
status is success), refuses it when it should not reach production, and writes
`sha` and `prev` to $GITHUB_OUTPUT plus a summary of what would ship to
$GITHUB_STEP_SUMMARY. `prev` is the commit on the `production` branch now
(empty before the first promote). `deploy` is false when production would not
change (only docs and tests, or with --auto the same commit), so the workflow
skips the approval and the deploy.

Run inside a full clone (fetch-depth 0) with origin/develop and, once it
exists, origin/production fetched. Needs GH_TOKEN and REPO for the status API.
"""

import json
import os
import re
import subprocess
import sys

SHA = re.compile(r"^[0-9a-f]{7,40}$")
# Changes that alter a production database: our knowledge-base schema files and
# the code that applies them, and the compose file (a Chatwoot image bump runs
# Chatwoot's own migrations). They need a backup first, which only /deploy does
# today (AGENTS.md §5).
NEEDS_BACKUP = re.compile(r"^ai-service/(internal/knowledge/(schema[^/]*\.sql|postgres\.go)|deploy/dokploy-compose\.yml)$")
# A `staging` status counts only when the GitHub Actions bot wrote it and the
# run it links to is the staging workflow, on develop, finished green.
STAGING_CREATOR = "github-actions[bot]"
STAGING_WORKFLOW = ".github/workflows/ai-service-staging.yml"
CI_WORKFLOW = ".github/workflows/ai-service.yml"
# Files that never reach the production image or its behaviour: Markdown docs
# (the Dockerfile ignores *.md, and nothing embeds them) and test code. A range
# of only these needs no deploy. testdata/ is not here: the image ships it.
NO_DEPLOY = re.compile(r"^(.*\.md|ai-service/docs/.*|.*_test\.go"
                       r"|ai-service/(deploy/promote|\.claude/skills/deploy)/test_[^/]*\.py)$")
RUN_URL = re.compile(r"^https://github\.com/[^/]+/[^/]+/actions/runs/([0-9]+)$")
CANDIDATES = 50


def valid_sha(value):
    return bool(SHA.match(value or ""))


def pick(candidates, staging_state):
    """The first (newest) candidate whose staging status is success."""
    for sha in candidates:
        if staging_state(sha) == "success":
            return sha
    return None


def refusals(sha, prev, on_develop, after_prev, staging, changed, ci=True):
    """Reasons not to promote sha; empty when it may go to production."""
    reasons = []
    if not ci:
        reasons.append(f"CI (the ai-service workflow on a push to develop) has not passed for {sha[:10]}")
    if not on_develop:
        reasons.append(f"{sha[:10]} is not on develop (its first-parent line)")
    if staging != "success":
        reasons.append(f"staging status is {staging or 'missing'}; promote only a commit that passed staging")
    if prev and sha != prev and not after_prev:
        reasons.append(f"{sha[:10]} is older than production ({prev[:10]}); that is a rollback, not a promote")
    risky = [f for f in changed if NEEDS_BACKUP.match(f)]
    if risky:
        reasons.append("the range can change a production database (" + ", ".join(risky)
                       + "); run /deploy, which takes a backup first")
    return reasons


def needs_deploy(changed, sha, prev, auto):
    """False when production would not change: the range holds only docs and
    tests, or (on an automatic run) production already is sha. A manual run of
    the same commit is a deliberate redeploy."""
    if prev and sha == prev:
        return not auto
    if not prev:
        return True
    return not changed or any(not NO_DEPLOY.match(f) for f in changed)


def trusted_staging_status(statuses):
    """The newest `staging` status written by the GitHub Actions bot, or None."""
    for status in statuses:
        if status.get("context") == "staging" and (status.get("creator") or {}).get("login") == STAGING_CREATOR:
            return status
    return None


def trusted_staging_state(statuses):
    status = trusted_staging_status(statuses)
    return status.get("state") if status else None


def run_id(url):
    match = RUN_URL.match(url or "")
    return match.group(1) if match else None


def is_staging_run(run, sha, repo):
    """True when run is a green staging run in repo, on develop, that tested sha."""
    return (run.get("path") == STAGING_WORKFLOW and run.get("head_branch") == "develop"
            and run.get("event") in ("workflow_run", "workflow_dispatch")
            and run.get("head_sha") == sha and (run.get("repository") or {}).get("full_name") == repo
            and run.get("conclusion") == "success")


def ci_green(runs):
    return any(r.get("path") == CI_WORKFLOW and r.get("event") == "push" and r.get("conclusion") == "success"
               for r in runs)


def git(*args, check=True):
    return subprocess.run(["git", *args], capture_output=True, text=True, check=check).stdout.strip()


def is_ancestor(older, newer):
    return subprocess.run(["git", "merge-base", "--is-ancestor", older, newer]).returncode == 0


def on_develop_line(sha):
    """True when sha is on develop's first-parent line (a merge into develop,
    not a commit from inside a merged branch)."""
    return sha in git("rev-list", "--first-parent", "origin/develop").split()


def gh_json(path):
    out = subprocess.run(["gh", "api", f"repos/{os.environ['REPO']}/{path}"], capture_output=True, text=True)
    return json.loads(out.stdout) if out.returncode == 0 and out.stdout else None


def staging_state(sha):
    """The trusted staging state of sha; a success whose run does not check out
    counts as "unverified"."""
    status = trusted_staging_status(gh_json(f"commits/{sha}/statuses?per_page=100") or [])
    if not status:
        return None
    if status.get("state") != "success":
        return status.get("state")
    rid = run_id(status.get("target_url"))
    run = gh_json(f"actions/runs/{rid}") if rid else None
    return "success" if run and is_staging_run(run, sha, os.environ["REPO"]) else "unverified"


def ci_passed(sha):
    runs = gh_json(f"actions/workflows/ai-service.yml/runs?head_sha={sha}&per_page=20") or {}
    return ci_green(runs.get("workflow_runs") or [])


def append(path_var, text):
    path = os.environ.get(path_var)
    if path:
        with open(path, "a", encoding="utf-8") as f:
            f.write(text)
    else:
        print(text, end="")


def check(requested, auto=False):
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
    reasons = refusals(sha, prev, on_develop_line(sha),
                       bool(prev) and is_ancestor(prev, sha), staging_state(sha), changed,
                       ci=ci_passed(sha))

    log = git("log", "--first-parent", "--format=- %h %s", f"{prev}..{sha}") if prev else "(first promote)"
    summary = (f"### Promote to production\n\n- commit: `{sha}`\n- production now: `{prev or 'none'}`\n\n"
               f"Ships:\n\n{log or '(nothing new: redeploy of the same commit)'}\n\n")
    deploy = needs_deploy(changed, sha, prev, auto)
    if reasons:
        summary += "**Refused:**\n\n" + "".join(f"- {r}\n" for r in reasons)
    elif not deploy:
        summary += ("**No deploy needed:** production already runs this commit, or the range "
                    "changes only docs and tests. Production stays where it is; the next real "
                    "promote ships these commits too.\n")
    append("GITHUB_STEP_SUMMARY", summary)
    if reasons:
        sys.exit("refused: " + "; ".join(reasons))
    append("GITHUB_OUTPUT", f"sha={sha}\nprev={prev or ''}\ndeploy={'true' if deploy else 'false'}\n")


def main(argv):
    auto = argv[1:2] == ["--auto"]
    rest = argv[2:] if auto else argv[1:]
    if not argv or argv[0] != "check" or len(rest) > 1:
        sys.exit("usage: promote.py check [--auto] [SHA]")
    check(rest[0] if rest else "", auto=auto)


if __name__ == "__main__":
    main(sys.argv[1:])
