# Captain Toolsets

## Status

Draft product and technical specification.

## Summary

Captain Toolsets is an open, GitHub-backed ecosystem for sharing and installing custom Captain tools. Publishers keep toolsets in any public GitHub repository. A static Astro catalog discovers repositories through the `captain-toolsets` GitHub topic, validates their manifests, and renders searchable documentation.

GitHub is the source of truth for published toolsets. Chatwoot stores only installed tool definitions, account-specific configuration, credentials, and enough source metadata to check for updates safely.

Users can also upload a YAML manifest directly. Manually imported toolsets do not require GitHub and are not linked to upstream updates.

## Goals

- Let anyone publish Captain toolsets from a GitHub repository.
- Let users browse toolsets through a fast, static catalog.
- Let users install a toolset from GitHub or import its YAML manually.
- Preserve the repository and commit from which a GitHub toolset was installed.
- Prevent upstream changes from silently changing an installed tool.
- Support explicit, reviewable updates.
- Avoid operating a package registry or hosting package artifacts.

## Non-goals

- Hosting toolset manifests outside their source repositories.
- Automatically applying upstream updates.
- Executing code from a toolset repository.
- Listing private repositories in the public catalog.
- Providing ratings, reviews, payments, or publisher analytics in the first version.
- Providing installation-count rankings in the first version.

## Terminology

- **Repository**: A GitHub repository containing one or more toolsets.
- **Toolset**: A folder containing a `toolset.yml` manifest and `README.md`.
- **Tool**: One HTTP action declared inside a toolset manifest.
- **Catalog**: The static Astro site generated from discovered repositories.
- **Installation**: An account-specific, locally materialized copy of a toolset.
- **Publisher**: The GitHub owner of the source repository.

## Repository contract

Publishers may use any repository name. A compatible repository has a root `README.md` and one direct child folder per toolset.

```text
customer-support-tools/
├── README.md
├── shopify/
│   ├── README.md
│   └── toolset.yml
└── linear/
    ├── README.md
    └── toolset.yml
```

Requirements:

- The repository must have the `captain-toolsets` GitHub topic to appear in the public catalog.
- The root `README.md` describes the collection.
- Toolset folders must be direct children of the repository root.
- Each toolset folder must contain `toolset.yml` and `README.md` using those exact names.
- The folder name is the toolset ID and must be URL-safe.
- Unrelated files and folders are ignored.
- A repository may contain any number of valid toolset folders within catalog limits.

The human-readable source coordinate includes the owner, repository, and folder:

```text
chatwoot/customer-support-tools/shopify
scmmishra/integration-tools/linear
```

A tool within a toolset has a stable coordinate:

```text
chatwoot/customer-support-tools/shopify#find_order
```

The GitHub owner controls the publisher namespace. A repository cannot claim another owner's namespace through manifest metadata.

## Manifest format

`toolset.yml` is a declarative manifest. It does not contain executable code.

```yaml
version: 1.2.0
kind: captain_toolset
name: Shopify Support Tools
description: Look up Shopify customers and orders.

inputs:
  shop_domain:
    label: Shop domain
    type: string
    placeholder: example.myshopify.com
    required: true

secrets:
  access_token:
    label: Admin API access token
    type: password
    required: true

tools:
  - id: find_order
    title: Find order
    description: Find a Shopify order by its order number.
    http_method: GET
    endpoint_url: https://${{ inputs.shop_domain }}/admin/api/orders.json
    auth_type: api_key
    auth_config:
      name: X-Shopify-Access-Token
      key: ${{ secrets.access_token }}
    param_schema:
      - name: order_number
        type: string
        required: true
        description: Order number supplied by the customer.
    enabled: true
```

Manifest rules:

- `version` is the publisher-controlled toolset release version.
- `kind` must be `captain_toolset`.
- The current manifest schema is implicitly version 1.
- Each tool must have an ID that remains stable across releases.
- Inputs use `${{ inputs.name }}` and secrets use `${{ secrets.name }}`.
- Runtime tool parameters use Liquid placeholders such as `{{ order_number }}`.
- Secret values must never be committed to a manifest.
- Unknown fields are rejected.
- YAML aliases and arbitrary object deserialization are disabled.

## Discovery

The catalog discovers public repositories using GitHub repository search and the `captain-toolsets` topic. A scheduled GitHub Actions workflow rebuilds the site approximately once per hour.

For each discovered repository, the builder:

1. Resolves the repository ID, default branch, and current commit SHA.
2. Fetches the root directory and root `README.md`.
3. Finds direct child directories containing `toolset.yml` and `README.md`.
4. Parses and validates each manifest.
5. Sanitizes each README.
6. Produces static toolset pages and a client-side search index.
7. Publishes the Astro build only when catalog generation succeeds.

The builder should use authenticated GitHub requests, pagination, and conditional requests. A transient GitHub failure must not replace the currently deployed catalog with an empty or partial build.

Invalid repositories or toolsets are excluded and reported in build output. Discovery through a topic is permissionless; inclusion does not imply endorsement.

## Catalog

Each toolset page should show:

- Name and description.
- Sanitized toolset README.
- GitHub owner and repository.
- Toolset folder and source link.
- Toolset version and indexed commit.
- Included tools and their declared capabilities.
- Required inputs and secrets without their values.
- Publisher verification status, when available.
- An install action that identifies the repository and manifest path.

The catalog may maintain small moderation files for verified publishers and blocked repositories. Verification provides a badge; unverified valid toolsets remain installable.

The catalog must never receive or proxy a user's tool credentials.

## Installation paths

### Install from GitHub

Users may start from the catalog or enter a GitHub repository URL directly in Chatwoot.

Chatwoot independently fetches and validates the manifest from GitHub. It must not trust manifest content copied from the catalog build.

The flow is:

1. Resolve the repository and selected toolset folder.
2. Fetch `toolset.yml` at a specific commit SHA.
3. Show a preview of tools, endpoints, authentication requirements, and requested inputs.
4. Collect required input and secret values.
5. Materialize the toolset and its tools locally in one atomic operation.
6. Record the source repository, path, commit, release version, and manifest digest.

### Manual import

Users may upload or paste a `toolset.yml` file.

The same parser, validation, preview, and credential collection flow is used. The resulting toolset has no upstream source and cannot check for GitHub updates. Manually imported tools remain editable and may be exported as YAML.

## Persistence

GitHub remains the source of truth for published documentation and manifests. Chatwoot persists installation state because credentials and account configuration are local, and because an installed toolset must continue working if its repository becomes unavailable.

Each GitHub installation records at least:

```text
provider                 github
repository_id            GitHub's immutable repository ID
repository_full_name     owner/repository
toolset_id               folder name
manifest_path            folder/toolset.yml
installed_commit         resolved commit SHA
installed_version        manifest version
manifest_digest          SHA-256 of normalized manifest content
```

Chatwoot also persists:

- Materialized tool definitions and stable tool IDs.
- Encrypted secret values.
- Input values.
- Per-tool enabled state.
- The association between tools and their toolset installation.

Directory listings and README content do not require durable persistence. They may be fetched on demand or cached temporarily.

## Editing and ownership

GitHub-installed manifest fields are managed by their source and are read-only in Chatwoot. Users may change local credentials, input values, and enabled state.

A **Customize** or **Detach from source** action converts the toolset to manual ownership. Detached tools become editable and stop receiving upstream update checks.

Manual imports are locally owned and editable from installation onward.

## Updates

Updates are explicit and user-initiated in the first version. No scheduled update polling or automatic application is required.

When the user selects **Check for updates**, Chatwoot:

1. Fetches the manifest from the source repository's default branch.
2. Compares its normalized digest and release version with the installed values.
3. Shows changes to tools, endpoints, methods, authentication, parameters, inputs, and secrets.
4. Requests any newly required configuration.
5. Applies the complete update atomically after confirmation.
6. Records the new commit, version, and digest.

Removed tools must be called out explicitly. Existing credentials may be reused only for secret IDs that remain unchanged. An upstream change must never take effect merely because a branch moved.

## Security and trust

Toolsets describe outbound HTTP requests and therefore require a strong trust boundary.

- Display the publisher, repository, commit, endpoints, and authentication behavior before installation.
- Sanitize all rendered Markdown and reject embedded scripts or unsafe HTML.
- Parse YAML using safe loading with aliases disabled.
- Enforce manifest, README, repository, and tool-count size limits.
- Validate supported HTTP methods, authentication types, schemas, and templates.
- Prevent manifests from supplying secret values.
- Encrypt account credentials at rest and never expose them to the catalog.
- Protect server-side requests against private-network and metadata-service access.
- Require confirmation when an update changes a destination host or authentication behavior.
- Distinguish verified publishers from merely valid manifests.
- Support blocking abusive repositories without making approval a prerequisite for publication.

## Private repositories

Private repositories are not included in the public Astro catalog. A user may install directly from a private GitHub repository when Chatwoot has user-authorized read access.

Private and public installations follow the same commit pinning, validation, preview, and update rules. Repository credentials must not be stored in the toolset manifest.

## Availability and failure behavior

- Installed tools run from their local materialized definitions and do not depend on GitHub availability.
- Catalog downtime does not prevent direct GitHub installation or manual import.
- Repository deletion does not delete an installed toolset.
- A failed import or update leaves the previous installation unchanged.
- An hourly indexing failure leaves the last successful catalog deployed.
- Repository renames are tracked using the immutable GitHub repository ID where possible.

## Initial delivery

### Phase 1: Manifest portability

- Import and export toolsets as YAML.
- Validate manifests and collect required inputs and secrets.

### Phase 2: GitHub installation

- Browse a supplied repository.
- Install a selected toolset at a resolved commit.
- Persist source provenance and group installed tools.
- Support detaching a GitHub-installed toolset.

### Phase 3: Static catalog

- Discover repositories through the `captain-toolsets` topic.
- Build the Astro catalog hourly.
- Render sanitized documentation and searchable toolset metadata.
- Link catalog installation into Chatwoot.

### Phase 4: Managed updates

- Check for updates on demand.
- Show a security-relevant manifest diff.
- Apply confirmed updates atomically.

## Acceptance criteria

- A publisher can expose multiple toolsets from an arbitrarily named public GitHub repository.
- Adding the `captain-toolsets` topic makes valid toolsets eligible for the next catalog build.
- Invalid manifests are excluded without breaking the deployed catalog.
- A user can install from the catalog, a GitHub repository URL, or a local YAML file.
- GitHub installations retain their repository, path, commit, and digest.
- Installed tools continue working when GitHub or the catalog is unavailable.
- Upstream changes do not affect installed tools until explicitly reviewed and applied.
- Manual imports work without GitHub and remain locally editable.
- Secrets never appear in manifests, catalog output, logs, exports, or update diffs.
