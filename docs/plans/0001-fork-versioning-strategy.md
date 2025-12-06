# Fork Versioning Strategy Plan

## Overview

This document describes the versioning strategy for the Chatwoot-BR fork that:
- Preserves upstream version visibility (e.g., `v4.8.0`)
- Adds fork revision tracking (e.g., `+1`, `+2`)
- Resets fork revision when syncing with upstream

## Chosen Version Format

```
v{MAJOR}.{MINOR}.{PATCH}+{FORK_REV}
```

**Examples:**
- `v4.8.0+1` - First fork release based on upstream v4.8.0
- `v4.8.0+2` - Second fork release (internal changes)
- `v4.9.0+1` - First fork release after syncing to upstream v4.9.0 (reset)

## Version Precedence

Per SemVer 2.0, build metadata (`+...`) is ignored for precedence:
- `v4.8.0` == `v4.8.0+1` == `v4.8.0+2` (for dependency resolution)
- This is acceptable since we control our own deployments

## Docker Tag Conversion

Docker tags don't support `+`, so GitHub Actions automatically converts:
- Git tag: `v4.8.0+1` → Docker tag: `v4.8.0-1`

This means:
- Source files (VERSION_CW, VERSION_CWCTL): Use `+` format
- Docker/Helm files (appVersion, image.tag): Use `-` format

## Files Modified During Release

### 1. `VERSION_CW` (line 1)
Plain version with fork revision using `+`:
```
4.8.0+1
```

### 2. `VERSION_CWCTL` (line 1)
Plain version with fork revision using `+`:
```
4.8.0+1
```

### 3. `package.json` (line 3)
Base version only (npm doesn't support `+`):
```json
"version": "4.8.0"
```

### 4. `charts/chatwoot/Chart.yaml`
- Line 32 `version`: Upstream version (chart compatibility)
- Line 35 `appVersion`: Full fork version with `-` (Docker tag)

```yaml
version: 4.8.0
appVersion: "v4.8.0-1"
```

### 5. `charts/chatwoot/values.yaml` (line 7)
Default image tag using `-` format:
```yaml
tag: v4.8.0-1
```

## Release Type Decision Tree

```
Is this release syncing with upstream?
├── YES: Upstream Sync Release
│   ├── Get upstream version (e.g., v4.9.0)
│   ├── Set fork revision to 1
│   └── Result: v4.9.0+1
│
└── NO: Fork-only Release
    ├── Keep current upstream version (e.g., v4.8.0)
    ├── Increment fork revision (+1 → +2)
    └── Result: v4.8.0+2
```

## CHANGELOG Format

```markdown
## [v4.8.0+2] - 2025-12-06

### Fork Changes
- Description of fork-specific change

---

## [v4.8.0+1] - 2025-12-05 (Synced with upstream v4.8.0)

### Upstream Changes
- Changes from upstream release

### Fork Changes
- Fork-specific additions
```

## GitHub Actions Workflows

### Tag Pattern
Workflows trigger on: `v[0-9]+.[0-9]+.[0-9]+*`

This matches both:
- Standard tags: `v4.8.0`
- Fork tags: `v4.8.0+1`

### Docker Tag Conversion in Workflow
```yaml
env:
  DOCKER_TAG: ${{ github.ref_name }} # v4.8.0+1
run: |
  TAG="${DOCKER_TAG//+/-}"  # v4.8.0-1
```

---

**Created**: 2025-12-06
**Status**: Implemented
**Upstream**: chatwoot/chatwoot
**Fork**: chatwoot-br/chatwoot
