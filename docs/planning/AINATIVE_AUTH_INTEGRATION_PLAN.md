# AINative Authentication Integration Plan

**Date:** December 17, 2025
**Status:** Planning
**Goal:** Replace Chatwoot's Devise authentication with AINative centralized auth

---

## Current State Analysis

### Chatwoot Authentication (Devise-based)

**Key Components:**
- **Gem:** `devise` + `devise_token_auth` (for API tokens)
- **Model:** `User` model with email/password
- **Features:**
  - Email/password login
  - OAuth (Google, SAML)
  - 2FA/MFA (TOTP)
  - Password recovery
  - Email confirmation
  - Session management
  - Remember me functionality

**Database Schema (`users` table):**
```ruby
- email (unique)
- encrypted_password
- reset_password_token
- confirmation_token
- current_sign_in_at
- last_sign_in_ip
- otp_secret (encrypted)
- otp_backup_codes (encrypted)
- provider (email/google_oauth2/saml)
- uid
- tokens (JSON - for API auth)
```

**Authentication Flow:**
1. User submits email/password → `SessionsController`
2. Devise validates credentials
3. Creates session cookie
4. For API: Returns JWT token in `tokens` JSON field
5. Subsequent requests: Token validation via `devise_token_auth`

### AINative Authentication (Unknown - Need to Investigate)

**Questions to Answer:**
- ✅ Does AINative have a public auth API?
- ✅ OAuth 2.0 / OpenID Connect support?
- ✅ User management endpoints?
- ✅ SSO capabilities?
- ✅ Multi-tenant account isolation?

**From searching ZeroDB commands, I found:**
- No dedicated auth endpoints in slash commands
- API uses `X-API-Key` header for authentication
- Project-level isolation via `ZERODB_PROJECT_ID`
- No user management API visible

---

## Integration Strategy: 3 Options

### Option 1: Keep Chatwoot Auth + Add AINative API Key Management ⭐ RECOMMENDED

**Approach:**
- Keep Devise for user authentication (login/signup)
- Store AINative API keys per account in encrypted fields
- Use Chatwoot's existing multi-tenancy (accounts)
- Map Chatwoot accounts → AINative projects

**Pros:**
- ✅ Minimal code changes
- ✅ Proven auth system (Devise)
- ✅ Keeps existing 2FA, OAuth, etc.
- ✅ Users don't need AINative accounts
- ✅ Chatwoot remains self-contained

**Cons:**
- ❌ Users managed in two systems
- ❌ No centralized user directory

**Implementation:**

```ruby
# Migration: Add AINative credentials to accounts
class AddAinativeCredentialsToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :ainative_project_id, :string
    add_column :accounts, :ainative_api_key_encrypted, :string
    add_column :accounts, :ainative_settings, :jsonb, default: {}

    add_index :accounts, :ainative_project_id, unique: true
  end
end

# Model: Account
class Account < ApplicationRecord
  encrypts :ainative_api_key_encrypted, deterministic: true

  def ainative_configured?
    ainative_project_id.present? && ainative_api_key_encrypted.present?
  end

  def ainative_client
    @ainative_client ||= Zerodb::Client.new(
      api_key: ainative_api_key_encrypted,
      project_id: ainative_project_id
    )
  end
end

# Service: Auto-create AINative project on account creation
class Ainative::ProjectProvisionService
  def initialize(account)
    @account = account
  end

  def provision!
    # Create AINative project via API
    response = HTTParty.post(
      "#{ENV['ZERODB_API_URL']}/projects",
      headers: { 'X-API-Key' => ENV['ZERODB_MASTER_API_KEY'] },
      body: {
        name: "Chatwoot Account: #{@account.name}",
        description: "Auto-provisioned for Chatwoot account ##{@account.id}"
      }.to_json
    )

    project = JSON.parse(response.body)

    @account.update!(
      ainative_project_id: project['id'],
      ainative_api_key_encrypted: project['api_key']
    )
  end
end

# Callback: Auto-provision on account creation
class Account < ApplicationRecord
  after_create :provision_ainative_project

  private

  def provision_ainative_project
    Ainative::ProjectProvisionService.new(self).provision! if Rails.env.production?
  rescue => e
    Rails.logger.error("AINative provisioning failed: #{e.message}")
  end
end
```

**Environment Variables:**
```bash
# Master API key for creating projects
ZERODB_MASTER_API_KEY=<admin key from AINative dashboard>
ZERODB_API_URL=https://api.ainative.studio/v1/public
```

---

### Option 2: AINative as SSO Provider (OAuth/SAML)

**Approach:**
- Use AINative as OAuth2/OpenID Connect provider
- Users login via AINative
- Chatwoot receives user info via OAuth callback
- Store AINative user ID in Chatwoot

**Pros:**
- ✅ Centralized user management
- ✅ Single sign-on experience
- ✅ AINative becomes identity provider

**Cons:**
- ❌ Requires AINative to support OAuth2 server
- ❌ Not currently available (based on research)
- ❌ Complex migration for existing users

**Status:** ⚠️ NOT FEASIBLE - AINative doesn't appear to offer OAuth2 server functionality

---

### Option 3: Custom Auth Bridge (Advanced)

**Approach:**
- Build custom auth service that syncs users between systems
- Chatwoot → AINative user sync on registration
- Shared JWT tokens validated by both systems

**Pros:**
- ✅ True unified authentication
- ✅ Users exist in both systems

**Cons:**
- ❌ High complexity
- ❌ Requires custom backend service
- ❌ Maintenance burden
- ❌ Overkill for current needs

**Status:** ⚠️ NOT RECOMMENDED - Too complex for current requirements

---

## Recommended Implementation: Option 1

### Phase 1: Database Schema (Week 1)

**Migration:**
```ruby
# db/migrate/20251217_add_ainative_to_accounts.rb
class AddAinativeToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :ainative_project_id, :string
    add_column :accounts, :ainative_api_key_encrypted, :string
    add_column :accounts, :ainative_settings, :jsonb, default: {
      embeddings_model: 'BAAI/bge-small-en-v1.5',
      vector_dimensions: 384,
      auto_indexing: true
    }

    add_index :accounts, :ainative_project_id, unique: true
  end
end
```

Run migration:
```bash
bundle exec rails db:migrate
```

### Phase 2: Model Encryption (Week 1)

**Update Account Model:**
```ruby
# app/models/account.rb
class Account < ApplicationRecord
  # Encrypt AINative API key
  encrypts :ainative_api_key_encrypted, deterministic: true

  # Validations
  validates :ainative_project_id, uniqueness: true, allow_nil: true

  # Instance methods
  def ainative_configured?
    ainative_project_id.present? && ainative_api_key_encrypted.present?
  end

  def ainative_client
    return unless ainative_configured?

    @ainative_client ||= Zerodb::Client.new(
      api_key: ainative_api_key_encrypted,
      project_id: ainative_project_id,
      api_url: ENV.fetch('ZERODB_API_URL', 'https://api.ainative.studio/v1/public')
    )
  end

  # Callbacks
  after_create :provision_ainative_project, if: -> { Rails.env.production? }

  private

  def provision_ainative_project
    Ainative::ProjectProvisionJob.perform_later(id)
  end
end
```

### Phase 3: Auto-Provisioning Service (Week 2)

**Background Job:**
```ruby
# app/jobs/ainative/project_provision_job.rb
module Ainative
  class ProjectProvisionJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: 5.seconds, attempts: 3

    def perform(account_id)
      account = Account.find(account_id)
      return if account.ainative_configured?

      service = ProjectProvisionService.new(account)
      service.provision!

      Rails.logger.info("AINative project provisioned for account #{account_id}")
    rescue => e
      Rails.logger.error("AINative provisioning failed for account #{account_id}: #{e.message}")
      raise
    end
  end
end
```

**Service:**
```ruby
# app/services/ainative/project_provision_service.rb
module Ainative
  class ProjectProvisionService
    include HTTParty
    base_uri ENV.fetch('ZERODB_API_URL', 'https://api.ainative.studio/v1/public')

    def initialize(account)
      @account = account
      @master_api_key = ENV['ZERODB_MASTER_API_KEY']
    end

    def provision!
      raise 'Master API key not configured' unless @master_api_key.present?

      # Create project
      project = create_project

      # Update account with credentials
      @account.update!(
        ainative_project_id: project['id'],
        ainative_api_key_encrypted: project['api_key']
      )

      # Initialize default settings
      initialize_project_settings(project['id'])

      project
    end

    private

    def create_project
      response = self.class.post(
        '/projects',
        headers: {
          'X-API-Key' => @master_api_key,
          'Content-Type' => 'application/json'
        },
        body: {
          name: "Chatwoot: #{@account.name}",
          description: "Auto-provisioned for Chatwoot account ##{@account.id}",
          tier: 'pro',
          settings: {
            chatwoot_account_id: @account.id,
            created_via: 'chatwoot_auto_provision'
          }
        }.to_json
      )

      raise "Project creation failed: #{response.body}" unless response.success?

      JSON.parse(response.body)
    end

    def initialize_project_settings(project_id)
      # Enable vector extension
      # Create default namespaces
      # Set up initial schemas
      # This would use the AINative API to configure the project
    end
  end
end
```

### Phase 4: Admin UI for Manual Configuration (Week 2)

**Admin Controller:**
```ruby
# app/controllers/super_admin/ainative_settings_controller.rb
class SuperAdmin::AinativeSettingsController < SuperAdmin::ApplicationController
  def show
    @account = Account.find(params[:account_id])
  end

  def update
    @account = Account.find(params[:account_id])

    if @account.update(ainative_params)
      redirect_to super_admin_account_path(@account), notice: 'AINative settings updated'
    else
      render :show
    end
  end

  def provision
    @account = Account.find(params[:account_id])

    Ainative::ProjectProvisionJob.perform_later(@account.id)

    redirect_to super_admin_account_path(@account),
                notice: 'AINative project provisioning started'
  end

  private

  def ainative_params
    params.require(:account).permit(
      :ainative_project_id,
      :ainative_api_key_encrypted,
      ainative_settings: [
        :embeddings_model,
        :vector_dimensions,
        :auto_indexing
      ]
    )
  end
end
```

**Admin View:**
```erb
<!-- app/views/super_admin/accounts/show.html.erb -->
<div class="ainative-section">
  <h3>🚀 AINative Integration</h3>

  <% if @account.ainative_configured? %>
    <div class="status-badge success">✓ Configured</div>

    <dl>
      <dt>Project ID:</dt>
      <dd><code><%= @account.ainative_project_id %></code></dd>

      <dt>API Key:</dt>
      <dd>
        <code>****<%= @account.ainative_api_key_encrypted.last(8) %></code>
        <button onclick="revealKey()">Reveal</button>
      </dd>

      <dt>Settings:</dt>
      <dd>
        <pre><%= JSON.pretty_generate(@account.ainative_settings) %></pre>
      </dd>
    </dl>

    <%= link_to 'Edit Settings', edit_super_admin_account_ainative_settings_path(@account) %>
  <% else %>
    <div class="status-badge warning">⚠ Not Configured</div>

    <%= form_with url: provision_super_admin_account_ainative_settings_path(@account), method: :post do %>
      <%= submit_tag 'Auto-Provision AINative Project',
                     class: 'btn btn-primary',
                     data: { confirm: 'Create AINative project for this account?' } %>
    <% end %>

    <p class="help-text">
      Or manually enter credentials below:
    </p>

    <%= form_with model: @account, url: super_admin_account_ainative_settings_path(@account) do |f| %>
      <%= f.text_field :ainative_project_id, placeholder: 'Project ID' %>
      <%= f.text_field :ainative_api_key_encrypted, placeholder: 'API Key' %>
      <%= f.submit 'Save Manually' %>
    <% end %>
  <% end %>
</div>
```

### Phase 5: User-Facing Features (Week 3-4)

**Account Settings Page:**
```vue
<!-- app/javascript/dashboard/routes/dashboard/settings/account/AinativeSettings.vue -->
<template>
  <div class="ainative-settings">
    <h2>🚀 AI Features (Powered by AINative)</h2>

    <div v-if="account.ainativeConfigured" class="configured">
      <status-badge type="success">AI Features Enabled</status-badge>

      <div class="feature-list">
        <feature-card
          icon="🔍"
          title="Semantic Search"
          description="Find conversations by meaning, not keywords"
          :enabled="settings.auto_indexing"
          @toggle="toggleFeature('auto_indexing')"
        />

        <feature-card
          icon="💡"
          title="Smart Suggestions"
          description="AI-powered canned response recommendations"
          :enabled="settings.smart_suggestions"
          @toggle="toggleFeature('smart_suggestions')"
        />

        <feature-card
          icon="🧠"
          title="Agent Memory"
          description="Remember customer preferences across conversations"
          :enabled="settings.agent_memory"
          @toggle="toggleFeature('agent_memory')"
        />
      </div>

      <div class="usage-stats">
        <h3>Usage This Month</h3>
        <stat-card label="Vectors Indexed" :value="stats.vectorsCount" />
        <stat-card label="Embeddings Generated" :value="stats.embeddingsCount" badge="FREE" />
        <stat-card label="Semantic Searches" :value="stats.searchesCount" />
      </div>
    </div>

    <div v-else class="not-configured">
      <p>AI features are not enabled for your account.</p>
      <p>Contact your administrator to enable AINative integration.</p>
    </div>
  </div>
</template>
```

---

## Migration Path for Existing Accounts

### Step 1: Backfill Existing Accounts

```ruby
# lib/tasks/ainative.rake
namespace :ainative do
  desc 'Provision AINative projects for existing accounts'
  task provision_existing_accounts: :environment do
    Account.where(ainative_project_id: nil).find_each do |account|
      puts "Provisioning account ##{account.id} (#{account.name})..."

      begin
        Ainative::ProjectProvisionJob.perform_now(account.id)
        puts "  ✓ Success"
      rescue => e
        puts "  ✗ Failed: #{e.message}"
      end

      sleep 1 # Rate limiting
    end
  end
end
```

Run:
```bash
bundle exec rake ainative:provision_existing_accounts
```

### Step 2: Enable Features Gradually

1. Week 1: Provision projects for all accounts
2. Week 2: Enable semantic search (opt-in)
3. Week 3: Enable smart suggestions (opt-in)
4. Week 4: Enable agent memory (opt-in)
5. Week 5: Make features opt-out

---

## Security Considerations

1. **API Key Encryption:**
   - Use Rails 7.1 `encrypts` with deterministic encryption
   - Keys stored encrypted at rest
   - Never log or expose in plain text

2. **Access Control:**
   - Only super admins can manage AINative settings
   - Account owners cannot see API keys
   - Audit log all credential changes

3. **API Rate Limiting:**
   - Implement exponential backoff in `Zerodb::BaseService`
   - Cache responses where appropriate
   - Monitor API usage per account

4. **Project Isolation:**
   - Each Chatwoot account = separate AINative project
   - No data sharing between accounts
   - Use project-level API keys, not master key

---

## Cost Management

**Per-Account Cost Estimation:**
```ruby
# app/services/ainative/cost_estimator.rb
module Ainative
  class CostEstimator
    def initialize(account)
      @account = account
    end

    def monthly_cost
      {
        vectors: vector_storage_cost,
        searches: search_cost,
        memory: memory_cost,
        total: total_cost
      }
    end

    private

    def vector_storage_cost
      vector_count = @account.ainative_client.vector_stats['count']
      (vector_count * 0.001).round(2) # $0.001 per vector
    end

    def search_cost
      monthly_searches = fetch_monthly_search_count
      (monthly_searches * 0.01).round(2) # $0.01 per search
    end

    def memory_cost
      # Free tier: 1GB, then $0.10/GB
      memory_gb = @account.ainative_client.memory_stats['size_gb']
      [0, (memory_gb - 1) * 0.10].max.round(2)
    end

    def total_cost
      vector_storage_cost + search_cost + memory_cost
    end
  end
end
```

**Display in Admin Dashboard:**
```erb
<div class="cost-summary">
  <h3>Estimated Monthly Cost</h3>
  <% cost = Ainative::CostEstimator.new(@account).monthly_cost %>

  <table>
    <tr>
      <td>Vector Storage</td>
      <td>$<%= cost[:vectors] %></td>
    </tr>
    <tr>
      <td>Searches</td>
      <td>$<%= cost[:searches] %></td>
    </tr>
    <tr>
      <td>Memory</td>
      <td>$<%= cost[:memory] %></td>
    </tr>
    <tr class="total">
      <td><strong>Total</strong></td>
      <td><strong>$<%= cost[:total] %></strong></td>
    </tr>
  </table>
</div>
```

---

## Python SDK Integration (Optional)

Since you mentioned the Python SDK, we could add Python-based background workers for heavy AI processing:

**Use Case: Async Embedding Generation**
```python
# scripts/ainative_worker.py
from ainative import Client
import os

client = Client(
    api_key=os.getenv('ZERODB_API_KEY'),
    project_id=os.getenv('ZERODB_PROJECT_ID')
)

def generate_embeddings_batch(texts):
    """Process large batches of embeddings using Python SDK"""
    result = client.embeddings.generate(
        texts=texts,
        model='BAAI/bge-small-en-v1.5',
        dimensions=384
    )
    return result.embeddings
```

**Integration with Chatwoot:**
```ruby
# Call Python script from Ruby
class Ainative::PythonEmbeddingService
  def generate_batch(texts)
    script_path = Rails.root.join('scripts', 'ainative_worker.py')

    result = `python #{script_path} --texts='#{texts.to_json}'`
    JSON.parse(result)
  end
end
```

---

## Next Steps

1. **Immediate (This Week):**
   - [ ] Verify AINative API supports project creation
   - [ ] Get master API key from AINative dashboard
   - [ ] Run database migration locally
   - [ ] Test manual account provisioning

2. **Short-term (Week 1-2):**
   - [ ] Implement auto-provisioning service
   - [ ] Build admin UI
   - [ ] Test with 5 test accounts
   - [ ] Document API integration

3. **Medium-term (Week 3-4):**
   - [ ] Backfill existing accounts
   - [ ] Enable features in production
   - [ ] Monitor costs and usage
   - [ ] Gather user feedback

4. **Optional Enhancements:**
   - [ ] Integrate Python SDK for batch processing
   - [ ] Build cost optimization tools
   - [ ] Create usage analytics dashboard

---

## Questions to Resolve

1. **Does AINative support programmatic project creation?**
   - Need to test `/projects` POST endpoint
   - Verify API key generation workflow

2. **What's the master API key scope?**
   - Can it create projects for other users?
   - Rate limits and quotas?

3. **Cost allocation:**
   - Bill per project or aggregate?
   - How to track costs per Chatwoot account?

4. **Python SDK advantages:**
   - Performance benefits over Ruby HTTParty?
   - Better for batch operations?

---

**Status:** Ready for implementation pending AINative API verification
**Recommended Approach:** Option 1 - Keep Chatwoot auth, add AINative as backend service
**Estimated Timeline:** 4 weeks for full implementation
