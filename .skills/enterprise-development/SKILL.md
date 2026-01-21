---
name: enterprise-development
description: Develop Enterprise Edition features for Chatwoot using the enterprise overlay pattern. Use this skill when adding premium features, extending OSS functionality for enterprise, or working with the enterprise directory structure.
metadata:
  author: chatwoot
  version: "1.0"
---

# Enterprise Edition Development

## Overview

Chatwoot has an Enterprise overlay under `enterprise/` that extends/overrides OSS code. Enterprise features are premium capabilities that build on top of the open-source foundation.

## Directory Structure

```
enterprise/
├── app/
│   ├── controllers/
│   ├── models/
│   │   └── concerns/
│   ├── policies/
│   ├── services/
│   └── views/
├── config/
│   ├── initializers/
│   └── routes/
├── lib/
└── LICENSE
```

## Core Principles

1. **Never modify OSS files for Enterprise-only features**
2. **Use extension points** (`prepend_mod_with`, `include_mod_with`)
3. **Keep API contracts stable** across OSS and Enterprise
4. **Mirror directory structure** between OSS and Enterprise

## Extension Patterns

### Adding Enterprise Behavior to Models

```ruby
# app/models/conversation.rb (OSS)
class Conversation < ApplicationRecord
  include_mod_with 'Conversation::EnterpriseFeatures'
  
  # OSS code...
end

# enterprise/app/models/concerns/conversation/enterprise_features.rb
module Conversation::EnterpriseFeatures
  extend ActiveSupport::Concern

  included do
    has_many :sla_events, dependent: :destroy
    
    scope :sla_breached, -> { where(sla_breached: true) }
  end

  def check_sla_compliance
    return unless account.enterprise?
    
    # Enterprise-specific logic
  end
end
```

### Extending Controllers

```ruby
# app/controllers/api/v1/accounts/conversations_controller.rb (OSS)
class Api::V1::Accounts::ConversationsController < Api::V1::Accounts::BaseController
  prepend_mod_with 'Api::V1::Accounts::ConversationsController'
  
  def index
    # OSS implementation
  end
end

# enterprise/app/controllers/concerns/api/v1/accounts/conversations_controller.rb
module Api::V1::Accounts::ConversationsController
  extend ActiveSupport::Concern

  def index
    super
    # Add enterprise-specific data
    @sla_status = calculate_sla_status(@conversations) if enterprise_account?
  end

  private

  def enterprise_account?
    Current.account.enterprise?
  end
end
```

### Extending Policies

```ruby
# app/policies/conversation_policy.rb (OSS)
class ConversationPolicy < ApplicationPolicy
  prepend_mod_with 'ConversationPolicy'
  
  def update?
    account_member?
  end
end

# enterprise/app/policies/concerns/conversation_policy.rb
module ConversationPolicy
  def update?
    return false if sla_locked?
    
    super
  end

  private

  def sla_locked?
    record.sla_locked? && !user.administrator?
  end
end
```

### Extending Services

```ruby
# app/services/conversations/resolve_service.rb (OSS)
class Conversations::ResolveService
  prepend_mod_with 'Conversations::ResolveService'
  
  def perform
    # OSS implementation
  end
end

# enterprise/app/services/concerns/conversations/resolve_service.rb
module Conversations::ResolveService
  def perform
    result = super
    
    record_sla_event if enterprise_enabled?
    
    result
  end

  private

  def record_sla_event
    SlaEvent.create!(
      conversation: @conversation,
      event_type: :resolved,
      occurred_at: Time.current
    )
  end

  def enterprise_enabled?
    @conversation.account.enterprise?
  end
end
```

## Creating Enterprise-Only Features

For features that exist only in Enterprise, place them directly under `enterprise/`:

```ruby
# enterprise/app/services/sla/breach_checker_service.rb
class Sla::BreachCheckerService
  def initialize(account:)
    @account = account
  end

  def perform
    return unless @account.enterprise?
    
    conversations_to_check.find_each do |conversation|
      check_and_notify(conversation)
    end
  end

  private

  def conversations_to_check
    @account.conversations.open.where('created_at < ?', sla_threshold)
  end

  def sla_threshold
    @account.sla_policy.response_time.ago
  end
end
```

## Enterprise Routes

```ruby
# enterprise/config/routes/enterprise_routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :accounts, only: [] do
        namespace :enterprise do
          resources :sla_policies
          resources :audit_logs, only: [:index, :show]
        end
      end
    end
  end
end
```

## Feature Flags

Use feature flags for gradual rollout:

```ruby
# Check enterprise feature availability
def sla_enabled?
  Current.account.feature_enabled?('sla_management')
end

# In views/controllers
if @account.enterprise? && @account.feature_enabled?('advanced_analytics')
  render_advanced_analytics
end
```

## Testing Enterprise Features

Add specs under `spec/enterprise/`:

```ruby
# spec/enterprise/services/sla/breach_checker_service_spec.rb
require 'rails_helper'

RSpec.describe Sla::BreachCheckerService do
  let(:account) { create(:account, :enterprise) }
  let(:service) { described_class.new(account: account) }

  describe '#perform' do
    context 'when enterprise account' do
      it 'checks SLA compliance' do
        conversation = create(:conversation, account: account, created_at: 2.hours.ago)
        
        expect { service.perform }
          .to change { conversation.reload.sla_breached }
          .from(false).to(true)
      end
    end

    context 'when non-enterprise account' do
      let(:account) { create(:account) }

      it 'does nothing' do
        expect(service.perform).to be_nil
      end
    end
  end
end
```

## Checklist for Enterprise Changes

Before making changes that impact core logic:

- [ ] Search for related files in both trees: `rg -n "ClassName|ServiceName" app enterprise`
- [ ] Check if Enterprise needs an override or extension point
- [ ] Avoid hardcoding instance/plan-specific behavior in OSS
- [ ] Keep request/response contracts stable
- [ ] Update both route sets when introducing new APIs
- [ ] Add Enterprise-specific specs under `spec/enterprise/`
- [ ] Mirror any renamed/moved shared code in `enterprise/`

## Common Patterns

### Checking Enterprise Status

```ruby
# In models
account.enterprise?

# In controllers
Current.account.enterprise?

# In views
<% if current_account.enterprise? %>
  <%= render 'enterprise_widget' %>
<% end %>
```

### Enterprise Migrations

Place in `enterprise/db/migrate/`:

```ruby
# enterprise/db/migrate/20240115000000_create_sla_policies.rb
class CreateSlaPolicies < ActiveRecord::Migration[7.0]
  def change
    create_table :sla_policies do |t|
      t.references :account, null: false, foreign_key: true
      t.integer :response_time_seconds
      t.integer :resolution_time_seconds
      t.timestamps
    end
  end
end
```

## Documentation

Reference: https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38
