---
name: rails-backend
description: Develop Ruby on Rails backend features for Chatwoot including models, services, controllers, and jobs. Use this skill when working on backend logic, database operations, background jobs, or Rails-specific patterns.
metadata:
  author: chatwoot
  version: "1.0"
---

# Rails Backend Development

## Project Structure

```
app/
├── controllers/     # API and web controllers
│   └── api/v1/     # Versioned API endpoints
├── models/          # ActiveRecord models
├── services/        # Business logic
├── jobs/            # Sidekiq background jobs
├── builders/        # Object builders
├── finders/         # Query objects
├── listeners/       # Event listeners
├── policies/        # Authorization policies
└── mailers/         # Email templates
```

## Ruby Style

Use compact module/class definitions:

```ruby
# ✅ Correct - compact style
module Api::V1
  class ConversationsController < Api::BaseController
    def index
      @conversations = Current.account.conversations
    end
  end
end

# ❌ Wrong - nested style
module Api
  module V1
    class ConversationsController < Api::BaseController
    end
  end
end
```

## Models

### Validations and Associations

```ruby
class Conversation < ApplicationRecord
  belongs_to :account
  belongs_to :inbox
  belongs_to :contact
  has_many :messages, dependent: :destroy
  has_many :attachments, through: :messages

  validates :account_id, presence: true
  validates :status, inclusion: { in: %w[open resolved pending] }

  enum status: { open: 0, resolved: 1, pending: 2 }

  scope :recent, -> { order(created_at: :desc) }
  scope :unresolved, -> { where.not(status: :resolved) }
end
```

### Indexes

Always add proper database indexes:

```ruby
# In migration
add_index :conversations, [:account_id, :status]
add_index :messages, :conversation_id
```

## Services

Place business logic in service objects:

```ruby
# app/services/conversations/resolve_service.rb
class Conversations::ResolveService
  def initialize(conversation:, user:)
    @conversation = conversation
    @user = user
  end

  def perform
    return if @conversation.resolved?

    ActiveRecord::Base.transaction do
      @conversation.update!(status: :resolved, resolved_at: Time.current)
      create_activity
      notify_contact
    end

    @conversation
  end

  private

  def create_activity
    @conversation.messages.create!(
      message_type: :activity,
      content: 'Conversation resolved',
      account_id: @conversation.account_id
    )
  end

  def notify_contact
    # notification logic
  end
end
```

## Controllers

### API Controllers

```ruby
class Api::V1::ConversationsController < Api::V1::Accounts::BaseController
  before_action :set_conversation, only: [:show, :update]
  before_action :check_authorization

  def index
    @conversations = Current.account
                           .conversations
                           .includes(:contact, :inbox)
                           .page(params[:page])
  end

  def show
    render json: @conversation
  end

  def update
    @conversation.update!(conversation_params)
    render json: @conversation
  end

  private

  def set_conversation
    @conversation = Current.account.conversations.find(params[:id])
  end

  def conversation_params
    params.require(:conversation).permit(:status, :assignee_id)
  end

  def check_authorization
    authorize @conversation || Conversation
  end
end
```

### Strong Parameters

Always use strong params:

```ruby
def message_params
  params.require(:message).permit(
    :content,
    :message_type,
    :private,
    attachments: []
  )
end
```

## Background Jobs

Use Sidekiq for background processing:

```ruby
# app/jobs/conversation_resolution_job.rb
class ConversationResolutionJob < ApplicationJob
  queue_as :default

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation

    Conversations::ResolveService.new(
      conversation: conversation,
      user: nil
    ).perform
  end
end

# Enqueue job
ConversationResolutionJob.perform_later(conversation.id)
```

## Error Handling

Use custom exceptions:

```ruby
# lib/custom_exceptions/conversation_errors.rb
module CustomExceptions
  class ConversationNotFound < StandardError; end
  class ConversationAlreadyResolved < StandardError; end
end

# In service
raise CustomExceptions::ConversationNotFound if @conversation.nil?
```

## Testing

```bash
# Run specific file
bundle exec rspec spec/models/conversation_spec.rb

# Run specific test
bundle exec rspec spec/models/conversation_spec.rb:42

# Run with coverage
COVERAGE=true bundle exec rspec
```

### Test Structure

```ruby
# spec/services/conversations/resolve_service_spec.rb
require 'rails_helper'

RSpec.describe Conversations::ResolveService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account, status: :open) }
  let(:user) { create(:user, account: account) }

  describe '#perform' do
    subject(:service) { described_class.new(conversation: conversation, user: user) }

    it 'resolves the conversation' do
      service.perform
      expect(conversation.reload.status).to eq('resolved')
    end

    context 'when already resolved' do
      let(:conversation) { create(:conversation, account: account, status: :resolved) }

      it 'does not change status' do
        expect { service.perform }.not_to change { conversation.reload.updated_at }
      end
    end
  end
end
```

### Test Helpers

Use `with_modified_env` instead of stubbing ENV:

```ruby
# ✅ Correct
it 'uses custom config' do
  with_modified_env(CUSTOM_VAR: 'value') do
    expect(MyService.new.config).to eq('value')
  end
end

# ❌ Wrong
it 'uses custom config' do
  allow(ENV).to receive(:[]).with('CUSTOM_VAR').and_return('value')
end
```

## RuboCop

Run linting before committing:

```bash
bundle exec rubocop -a
```

Max line length: 150 characters

## Enterprise Features

For Enterprise-only features:

1. Check for existing files in `enterprise/`
2. Use `prepend_mod_with` or `include_mod_with` for overrides
3. Add specs under `spec/enterprise/`

```ruby
# app/models/conversation.rb (OSS)
class Conversation < ApplicationRecord
  include_mod_with 'Conversation::EnterpriseFeatures'
end

# enterprise/app/models/concerns/conversation/enterprise_features.rb
module Conversation::EnterpriseFeatures
  extend ActiveSupport::Concern
  
  included do
    # Enterprise-only code
  end
end
```
