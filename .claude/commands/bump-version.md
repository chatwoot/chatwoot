# Bump Version Command

This command updates the app version across deployment files for a specific environment.

## Arguments

```
$ARGUMENTS
```

## Instructions

### Step 1: Parse Arguments

Parse the arguments provided above:
- **First argument** (required): Environment - must be one of: `dev`, `staging`, or `prod`
- **Second argument** (optional): New version in format `vX.Y.Z` (e.g., `v1.0.90`)

If no environment is provided or it's invalid, display an error message explaining the valid options.

### Step 2: Map Environment to Files

Based on the environment, determine which files to update:

**Development (`dev`):**
- `.github/workflows/deploy-development.yml` (2 version tags: rails-dev and vite-dev)
- `k8s/development/rails-deployment.yaml`
- `k8s/development/vite-deployment.yaml`
- `k8s/development/sidekiq-deployment.yaml`

**Staging (`staging`):**
- `.github/workflows/deploy-staging.yml` (2 version tags: rails-staging and vite-staging)
- `k8s/staging/rails-deployment.yaml`
- `k8s/staging/vite-deployment.yaml`
- `k8s/staging/sidekiq-deployment.yaml`

**Production (`prod`):**
- `.github/workflows/deploy.yml` (2 version tags: rails and vite)
- `k8s/production/rails-deployment.yaml`
- `k8s/production/vite-deployment.yaml`
- `k8s/production/sidekiq-deployment.yaml`

### Step 3: Detect Current Version

Read one of the target files (preferably the rails-deployment.yaml) and extract the current version using the pattern `:v\d+\.\d+\.\d+` from the Docker image tag.

The version format is: `wavai/chatwoot-{component}[-{env}]:vX.Y.Z`

### Step 4: Calculate New Version

- If a version was specified as the second argument, use that version
- If no version was specified, auto-increment the patch version:
  - `v1.0.86` → `v1.0.87`
  - `v1.2.9` → `v1.2.10`
  - `v2.0.99` → `v2.0.100`

Validate that the new version follows the format `vX.Y.Z` where X, Y, Z are non-negative integers.

### Step 5: Update Files

Use the Edit tool to replace the old version with the new version in all environment-specific files.

**Important:** Only replace version tags that match the environment's image naming pattern:
- For `dev`: Replace `:v{old}` with `:v{new}` in images containing `-dev:`
- For `staging`: Replace `:v{old}` with `:v{new}` in images containing `-staging:`
- For `prod`: Replace `:v{old}` with `:v{new}` in images like `chatwoot-rails:` and `chatwoot-vite:` (no suffix)

### Step 6: Report Changes

After updating, display a summary:

```
✅ Version Bump Complete

Environment: {environment}
Previous Version: {old_version}
New Version: {new_version}

Files Updated:
- {file1}
- {file2}
- {file3}
- {file4}
```

## Examples

```bash
/bump-version dev                    # Bump development to next patch version
/bump-version staging                # Bump staging to next patch version
/bump-version prod                   # Bump production to next patch version
/bump-version dev v1.0.90            # Set development to specific version
/bump-version staging v2.0.0         # Set staging to specific version
/bump-version prod v1.1.0            # Set production to specific version
```

## Error Handling

- If environment is missing or invalid, show: "Error: Please specify a valid environment: dev, staging, or prod"
- If version format is invalid, show: "Error: Invalid version format. Use vX.Y.Z (e.g., v1.0.90)"
- If a file cannot be found, report which file is missing and continue with others
