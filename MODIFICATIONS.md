# Modifications for Extended Community Edition

This document tracks all modifications made to the original Chatwoot codebase to create the Extended Community Edition. Use this to understand why changes were made and to help with merging upstream updates.

## DevContainer Configuration

### `.devcontainer/Dockerfile`

- **Change**: Added `--chown=vscode:vscode` to `COPY` commands for dependency files.
- **Reason**: Fixes permission errors during `bundle install` by ensuring the non-root user owns the dependency files.
- **Original**: `COPY package.json pnpm-lock.yaml ./`
- **Modified**: `COPY --chown=vscode:vscode package.json pnpm-lock.yaml ./`

### `.devcontainer/devcontainer.json`

- **Change**: Added `"workspaceFolder": "/workspace"`.
- **Reason**: Explicitly sets the workspace directory for the devcontainer.
- **Original**: No explicit workspace folder set.

### `.devcontainer/scripts/setup.sh`

- **Change**: Wrapped `gh codespace` commands in check for `CODESPACE_NAME` environment variable.
- **Reason**: Prevents script failure when running in local devcontainer (not GitHub Codespaces).
- **Original**: `gh codespace ports visibility 3000:public 3036:public 8025:public -c $CODESPACE_NAME || true`
- **Modified**: Wrapped in `if [ -n "$CODESPACE_NAME" ]; then ... fi`

## Backend Configuration

### `lib/chatwoot_app.rb`

- **Change 1**: Modified `enterprise?` method to check for `extended/` directory instead of `enterprise/`.
- **Reason**: Enables enterprise logic when the `extended` directory is present.
- **Original**: `@enterprise ||= root.join('enterprise').exist?`
- **Modified**: `@enterprise ||= root.join('extended').exist?`

- **Change 2**: Renamed environment variable from `DISABLE_ENTERPRISE` to `DISABLE_EXTENDED`.
- **Reason**: Consistent naming with the new directory structure.
- **Original**: `return if ENV.fetch('DISABLE_ENTERPRISE', false)`
- **Modified**: `return if ENV.fetch('DISABLE_EXTENDED', false)`

- **Change 3**: Updated `extensions` method to return `['extended']` instead of `['enterprise']`.
- **Reason**: Registers the `extended` extension for module injection.
- **Original**: `%w[enterprise]` or `%w[enterprise custom]`
- **Modified**: `%w[extended]` or `%w[extended custom]`

### `lib/chatwoot_hub.rb`

- **Change 1**: Hardcoded `pricing_plan` to always return `'community'`.
- **Reason**: Forces the application to run in Community mode without license checks, making all extended features available by default.
- **Original**: Complex logic checking `InstallationConfig` for pricing plan
- **Modified**: Simply returns `'community'`

- **Change 2**: Hardcoded `pricing_plan_quantity` to always return `0`.
- **Reason**: Sets unlimited seats/agents for the Community edition.
- **Original**: Logic checking `InstallationConfig` for quantity
- **Modified**: Simply returns `0`

### `config/application.rb`

- **Change**: Updated all paths to load from `extended/` instead of `enterprise/`.
- **Reason**: Loads code, views, and initializers from our custom `extended` directory.
- **Paths Changed**:
  - `config.eager_load_paths << Rails.root.join('extended/lib')`
  - `config.eager_load_paths << Rails.root.join('extended/listeners')`
  - `config.eager_load_paths += Dir["#{Rails.root}/extended/app/**"]`
  - `config.paths['app/views'].unshift('extended/app/views')`
  - `enterprise_initializers = Rails.root.join('extended/config/initializers')`

### `config/routes.rb`

- **Change**: Updated route namespace from `:enterprise` to `scope path: :extended, module: :enterprise`.
- **Reason**: Maps the `/extended` URL path to the `Enterprise` module namespace, matching our new branding and directory structure while keeping the internal module references working.
- **Original**: `namespace :enterprise, defaults: { format: 'json' } do`
- **Modified**: `scope path: :extended, module: :enterprise, as: :extended, defaults: { format: 'json' } do`

### `config/initializers/01_inject_enterprise_edition_module.rb`

- **Change 1**: Added mapping to convert `'extended'` extension name to `'Enterprise'` module namespace.
- **Reason**: The code in `extended/` still uses the `Enterprise::` module namespace. This mapping ensures the module injector finds the correct module even though the directory is named `extended`.
- **Original**: `module_name = extension_name.camelize`
- **Modified**: `module_name = extension_name == 'extended' ? 'Enterprise' : extension_name.camelize`

- **Change 2**: Added nil/false check to `const_get_maybe_false` method.
- **Reason**: Prevents `NoMethodError` when `mod` is `false` or `nil`.
- **Original**: No check, would call methods on `false`/`nil`
- **Modified**: `return false unless mod`

## Frontend Configuration

### `app/javascript/dashboard/composables/useConfig.js`

- **Change**: Forced `isEnterprise` to always return `true`.
- **Reason**: Tells frontend components that Enterprise features are available, unlocking UI elements.
- **Original**: `const isEnterprise = config.isEnterprise === 'true';`
- **Modified**: `const isEnterprise = true;`

### `app/javascript/dashboard/composables/usePolicy.js`

- **Change 1**: Forced `INSTALLATION_TYPES.ENTERPRISE` check to always return `true`.
- **Reason**: Shows Enterprise-only features even when running in Community mode.
- **Original**: `[INSTALLATION_TYPES.ENTERPRISE]: isEnterprise,`
- **Modified**: `[INSTALLATION_TYPES.ENTERPRISE]: true,`

- **Change 2**: Forced `hasPremiumEnterprise` computed property to always return `true`.
- **Reason**: Removes paywalls from Enterprise features.
- **Original**: `if (isEnterprise) return enterprisePlanName !== 'community';`
- **Modified**: `return true;`

- **Change 3**: Removed unused `enterprisePlanName` variable.
- **Reason**: No longer needed since we always return `true` for premium features.
- **Original**: `const { isEnterprise, enterprisePlanName } = useConfig();`
- **Modified**: `const { isEnterprise } = useConfig();`

### `app/helpers/super_admin/features.yml`

- **Change**: Set `enabled: true` for all premium features (Captain, SAML SSO, Custom Branding, Agent Capacity, Audit Logs, Disable Branding).
- **Reason**: Unlocks all premium features in the Super Admin panel regardless of pricing plan.
- **Original**: `enabled: <%= (ChatwootHub.pricing_plan != 'community') %>`
- **Modified**: `enabled: true`

## Controllers & Views

### `app/controllers/dashboard_controller.rb`

- **Change 1**: Set `IS_ENTERPRISE` to `false` in frontend config.
- **Reason**: Ensures the frontend displays "Community Edition" branding while still having all extended features available.
- **Original**: `IS_ENTERPRISE: ChatwootApp.enterprise?` or `IS_ENTERPRISE: ChatwootHub.pricing_plan != 'community'`
- **Modified**: `IS_ENTERPRISE: false`

- **Change 2**: Removed `pricing_plan` check for SAML login availability.
- **Reason**: Allows SAML login to be enabled via config even on Community plan.
- **Original**: `methods << 'saml' if ChatwootHub.pricing_plan != 'community' && GlobalConfigService.load('ENABLE_SAML_SSO_LOGIN', 'true').to_s != 'false'`
- **Modified**: `methods << 'saml' if GlobalConfigService.load('ENABLE_SAML_SSO_LOGIN', 'true').to_s != 'false'`

### `extended/app/controllers/enterprise/super_admin/app_configs_controller.rb`

- **Change**: Removed `pricing_plan` check that blocked access to premium configuration pages.
- **Reason**: Allows access to premium configuration pages (SAML, Captain, Custom Branding, etc.) in Super Admin.
- **Original**: `return super if ChatwootHub.pricing_plan == 'community'`
- **Modified**: Check removed entirely

### `extended/app/views/fields/account_features_field/_form.html.erb`

- **Change**: Removed `disabled` attribute logic for premium feature checkboxes.
- **Reason**: Allows toggling premium features in Super Admin account settings.
- **Original**: `should_disable = ChatwootHub.pricing_plan == 'community'`
- **Modified**: `should_disable = false`

## Models

### `app/models/inbox.rb`

- **Change**: Updated comment reference from `enterprise/` to `extended/`.
- **Reason**: Points to the correct location of the override.
- **Original**: `# overridden in enterprise/app/models/enterprise/inbox.rb`
- **Modified**: `# overridden in extended/app/models/extended/inbox.rb`

## Services & Libraries

### `lib/integrations/openai/processor_service.rb`

- **Change**: Updated path for enterprise OpenAI prompts from `enterprise/` to `extended/`.
- **Reason**: Points to the correct directory for prompt files.
- **Original**: `path = enterprise ? 'enterprise/lib/enterprise/integrations/openai_prompts' : 'lib/integrations/openai/openai_prompts'`
- **Modified**: `path = enterprise ? 'extended/lib/enterprise/integrations/openai_prompts' : 'lib/integrations/openai/openai_prompts'`

### `extended/lib/captain/prompt_renderer.rb`

- **Change**: Updated template path from `enterprise/` to `extended/`.
- **Reason**: Ensures the renderer looks for liquid templates in the correct `extended` directory.
- **Original**: `template_path = Rails.root.join('enterprise', 'lib', 'captain', 'prompts', "#{template_name}.liquid")`
- **Modified**: `template_path = Rails.root.join('extended', 'lib', 'captain', 'prompts', "#{template_name}.liquid")`

## Tasks & Configuration

### `lib/tasks/auto_annotate_models.rake`

- **Change**: Updated model directory path from `enterprise/app/models` to `extended/app/models`.
- **Reason**: Ensures annotate gem processes models in the correct directory.
- **Original**: `'model_dir' => ['app/models', 'enterprise/app/models']`
- **Modified**: `'model_dir' => ['app/models', 'extended/app/models']`

### `.rubocop.yml`

- **Change**: Updated all exclude paths from `enterprise/` to `extended/`.
- **Reason**: Ensures RuboCop applies rules to the correct directory.
- **Examples**:
  - `extended/lib/captain/agent.rb`
  - `extended/app/helpers/captain/chat_helper.rb`
  - `extended/app/models/captain/assistant.rb`
- **Change 2**: Added explicit exclusion for `enterprise/` directory.
- **Reason**: Prevents linting errors from the original enterprise code which is not being used/maintained.
- **Modified**: Added `- 'enterprise/**/*'` to `Exclude` list.

### `.rspec`

- **Change**: Added exclusion for `spec/enterprise/**/*_spec.rb`.
- **Reason**: Prevents running the original enterprise specs which would fail due to path changes. We now run specs in `spec/extended/`.
- **Modified**: Added `--exclude-pattern 'spec/enterprise/**/*_spec.rb'`

## Specs (Test Files)

**Note**: A new `spec/extended/` directory was created to house tests for the extended functionality. The original `spec/enterprise/` directory is excluded from test runs.

All spec files that referenced `/enterprise/` API endpoints or paths were updated to `/extended/`:

### `spec/enterprise/controllers/enterprise/api/v1/accounts_controller_spec.rb`

- **Change**: Updated all API endpoint URLs from `/enterprise/api/v1/...` to `/extended/api/v1/...`.
- **Reason**: Tests need to match the actual API routes.

### `spec/enterprise/controllers/enterprise/webooks/firecrawl_controller_spec.rb`

- **Change**: Updated webhook URLs from `/enterprise/webhooks/firecrawl` to `/extended/webhooks/firecrawl`.
- **Reason**: Tests need to match the actual webhook routes.

### `spec/enterprise/controllers/enterprise/webooks/stripe_controller_spec.rb`

- **Change**: Updated webhook URLs from `/enterprise/webhooks/stripe` to `/extended/webhooks/stripe`.
- **Reason**: Tests need to match the actual webhook routes.

### `spec/enterprise/lib/captain/prompt_renderer_spec.rb`

- **Change**: Updated template path from `enterprise/lib/captain/prompts/` to `extended/lib/captain/prompts/`.
- **Reason**: Tests need to reference the correct file paths.

### `spec/lib/integrations/openai/processor_service_spec.rb`

- **Change**: Updated prompt file path from `enterprise/lib/enterprise/integrations/openai_prompts/` to `extended/lib/enterprise/integrations/openai_prompts/`.
- **Reason**: Tests need to reference the correct file paths.

## Miscellaneous

### `package.json`

- **Change**: Updated `dev` script to remove stale socket file before starting overmind.
- **Reason**: Prevents `pnpm dev` from failing if a stale `.overmind.sock` file exists.
- **Original**: `"dev": "overmind start -f ./Procfile.dev"`
- **Modified**: `"dev": "rm -f .overmind.sock && overmind start -f ./Procfile.dev"`

## Summary

All modifications follow a consistent pattern:

1. **Directory Migration**: Changed all references from `enterprise/` to `extended/`
2. **Feature Unlocking**: Removed all pricing plan checks and forced enterprise features to be enabled
3. **Branding**: Kept "Community Edition" branding while unlocking all features
4. **Documentation**: Added inline comments explaining each change with original code preserved

This approach allows us to:

- Maintain the "Community Edition" branding
- Unlock all enterprise features by default
- Keep the codebase maintainable for future upstream merges
- Clearly document every modification for transparency
