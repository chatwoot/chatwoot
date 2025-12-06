Create a new release for this Chatwoot fork. We use the version format `vX.Y.Z+N` where X.Y.Z is the upstream version and N is our fork revision.

Follow these steps:

1. **Determine release type** by reviewing changes:
   - Run `git describe --tags --abbrev=0` to get current version
   - Run `git log $(git describe --tags --abbrev=0)..HEAD --oneline` to see changes
   - Check upstream for new releases: `git fetch upstream && git log upstream/master --oneline -5`
   - Ask me: **Upstream sync** (syncing with upstream) or **Fork-only** (our own changes)?

   **Version calculation:**
   - **Upstream sync**: Use new upstream version + reset fork rev to 1 (e.g., `v4.9.0+1`)
   - **Fork-only**: Keep upstream version + increment fork rev (e.g., `v4.8.0+1` → `v4.8.0+2`)

2. **Run pre-release checks**:
   - Run Ruby tests: `bundle exec rspec`
   - Run JS tests: `pnpm test`
   - Run linting: `pnpm eslint && bundle exec rubocop -a`
   - Verify working directory is clean with `git status`

3. **Update version in these files** (use the new version number):
   - `VERSION_CW` line 1: `X.Y.Z+N` (e.g., `4.8.0+1`)
   - `VERSION_CWCTL` line 1: `X.Y.Z+N` (e.g., `4.8.0+1`)
   - `package.json` line 3: `"version": "X.Y.Z"` (base version only, no +N)
   - `charts/chatwoot/Chart.yaml` line 32: `version: X.Y.Z` (upstream version)
   - `charts/chatwoot/Chart.yaml` line 35: `appVersion: "vX.Y.Z-N"` (use `-` not `+` for Docker)
   - `charts/chatwoot/values.yaml` line 7: `tag: vX.Y.Z-N` (use `-` not `+` for Docker)

4. **Update CHANGELOG.md** at the top with the new version section:

   For upstream sync:
   ```markdown
   ## [vX.Y.Z+1] - YYYY-MM-DD (Synced with upstream vX.Y.Z)

   ### Upstream Changes
   - List changes from upstream

   ### Fork Changes
   - Our additions (if any)
   ```

   For fork-only:
   ```markdown
   ## [vX.Y.Z+N] - YYYY-MM-DD

   ### Fork Changes
   - Description of changes
   ```

5. **Commit and tag**:
   ```bash
   git add VERSION_CW VERSION_CWCTL package.json charts/chatwoot/Chart.yaml charts/chatwoot/values.yaml CHANGELOG.md
   # For fork-only:
   git commit -m "chore: bump version to vX.Y.Z+N"
   # For upstream sync:
   git commit -m "chore: sync upstream vX.Y.Z and bump to vX.Y.Z+1"
   git tag -a vX.Y.Z+N -m "Release vX.Y.Z+N"
   ```

6. **Show me the commands to push** (do not push automatically):
   ```bash
   git push origin <current-branch>
   git push origin vX.Y.Z+N
   ```

**Important Notes:**
- Git tags use `+` (e.g., `v4.8.0+1`)
- Docker/Helm files use `-` (e.g., `v4.8.0-1`) because Docker doesn't support `+`
- GitHub Actions will auto-convert `+` to `-` for Docker image tags

Reference: docs/release-process.md
