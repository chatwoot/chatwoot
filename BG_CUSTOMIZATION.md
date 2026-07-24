# BG Chatwoot Customization

This fork keeps the full upstream Chatwoot history and carries the minimal BG
customization needed for production.

## Current Baseline

- Upstream: `https://github.com/chatwoot/chatwoot`
- Upstream tag: `v4.11.1`
- Upstream commit: `a08125e283b8e15b84b5073def1e785137b059ba`
- Maintenance branch: `bg/v4.11.1-avatar-proxy`

## Local Changes

1. `Avatarable#avatar_url` generates an Active Storage representation proxy
   URL so Cloudflare can cache the image bytes instead of a private S3 redirect.
2. `docker/Dockerfile` accepts `SOURCE_COMMIT`, so Jenkins can record the exact
   fork commit in `/app/.git_sha` even when Git metadata is excluded from the
   Docker build context.
3. The build and deployment Pipeline is maintained in
   `bluegame-studio/bg-devops` at
   `jenkinsfile/deploy/chatwoot-bg-build-deploy.jenkinsfile`.

## Upgrade Workflow

1. Fetch upstream branches and tags.
2. Create a new BG maintenance branch from the target upstream tag.
3. Cherry-pick or reapply the small BG customization commit.
4. Run the focused validation and build a new immutable image.
5. Run the Jenkins job with the new maintenance branch selected.

Do not merge an upstream version change directly into the production branch
without reviewing Chatwoot migrations, release notes, and the avatar URL code.
