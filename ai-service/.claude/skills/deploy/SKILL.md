---
name: deploy
description: Deploy the current origin/develop of the Chatwoot fork to production through Dokploy, then verify it. Only the owner starts this; running /deploy is the owner's go-ahead for one deploy of the commit shown in step 1.
disable-model-invocation: true
argument-hint: "[expected commit sha, optional]"
---

# /deploy — release origin/develop to production

The procedure behind `ai-service/deploy/README.md` ("Release a change"), as one
command. The owner typed `/deploy`, which authorizes **one** deploy of the
commit you show in step 1. Anything unexpected below means stop and ask, not
work around it. Helper: `ai-service/.claude/skills/deploy/dokploy.py` (paths
below are relative to the fork root; it reads Dokploy settings from the
workspace `.env.supabase` and never prints secrets).

Staging: every command below takes `--target staging` (for example
`dokploy.py --target staging deploy`); see `deploy/README.md` → Staging.
Staging deploys need no owner go-ahead; production deploys always do.

**Production deploys the `production` branch, not develop** (#39). The normal
path is the "ai-service promote" workflow, which moves that branch to a commit
that passed staging after the owner approves it in GitHub:
`gh workflow run ai-service-promote.yml --repo DEV-Johnstocker/chatwoot -f sha=<sha>`.
Use this skill when the workflow refuses on purpose (a schema change, which
needs the backup first) or GitHub is unavailable. Then step 3 moves the
`production` branch yourself before deploying.

## 1. What would be deployed

```bash
git fetch -q origin develop
git log -1 --format='%H %s' origin/develop
python3 ai-service/.claude/skills/deploy/dokploy.py status
```

- `status` must show `branch=production`. Note `deployed_commit`.
- If `$ARGUMENTS` names a commit, it must equal `origin/develop`; otherwise
  stop and say which is which.
- If `deployed_commit` already equals `origin/develop`, say so and stop:
  nothing to deploy.
- List what changes: `git log --oneline <deployed_commit>..origin/develop`
  and `git diff --stat <deployed_commit>..origin/develop -- ai-service .github`.

## 2. Gates — stop and ask if any fails

1. **No deploy running**: `running_deploys=0` in `status`.
2. **CI green on that exact commit** (the ai-service workflow runs on pushes
   to develop that touch `ai-service/`):
   `gh api repos/DEV-Johnstocker/chatwoot/commits/<sha>/check-runs --jq '.check_runs[] | select(.name | IN("Test, vet, format","govulncheck","Docker build","Secret scan (gitleaks)","actionlint")) | "\(.name) \(.conclusion)"'`.
   All five must be `success` (Chatwoot's own Rails/JS jobs also run on
   develop; they are not a gate for ai-service). If the range changes no
   ai-service files and no jobs ran, say so; that is acceptable.
3. **No schema change**: `git diff --stat <deployed_commit>..origin/develop --
   ai-service/internal/knowledge/` shows no `schema*.sql` and no change to
   `Migrate`. If it does, stop: AGENTS.md §5 (backup → apply → check) comes
   first, with the owner.
4. **Compose or env change**: if `ai-service/deploy/dokploy-compose.yml`
   changed and added a `${VAR:?}`, confirm the Dokploy env has that name
   (names only, never values) before deploying.
5. **Other sessions**: if `ListAgents` shows other Claude sessions on this
   project, message them that a deploy is starting and wait for any that are
   mid-deploy.

## 3. Deploy

```bash
git push origin <sha>:refs/heads/production    # fast-forward only; never force
python3 ai-service/.claude/skills/deploy/dokploy.py deploy
```

Dokploy builds the tip of `production`, so move the branch first. It refuses if a deploy is running, starts one, and waits (up to 30 minutes)
for `done` or `error`. Run it in the background and wait for the
notification; do not start a second deploy if it times out — check Dokploy.
The printed commit must be the one from step 1.

## 4. Verify

```bash
python3 ai-service/.claude/skills/deploy/dokploy.py verify
```

Public checks (`/api` 200, `/app/login` 200, public `/admin` 404, unsigned
webhook 401) plus every container `Up` and not unhealthy. Rails can take a few
minutes to turn healthy after migrations; rerun once after two minutes before
calling it failed. Then look for errors since the deploy:

```bash
ssh llmopshostinger 'docker logs --since 15m <app>-sidekiq-1 2>&1 | grep -ciE "error|fatal"; docker logs --since 15m <app>-ai-service-1 2>&1 | grep -c "\"level\":\"ERROR\""'
```

(`<app>` is the `app=` value from `status`.) One `rejected webhook` WARN is
the unsigned verify request.

## 5. Report

Lead with the result: deployed commit, what changed (PR titles), each check
with PASS/FAIL, and anything left open. If verification fails: say so with the
output, do not redeploy on your own; rollback is the owner's call: move
`production` back to the previous commit (`git push --force-with-lease=production:<bad> origin <previous>:refs/heads/production`)
and deploy, or revert PR → merge → promote (code only; a schema change does
not roll back).
