---
name: api-development
description: Build and modify REST APIs in Chatwoot following versioned API patterns. Use this skill when creating API endpoints, handling authentication, implementing serializers, or working with the API layer.
metadata:
  author: chatwoot
  version: "1.0"
---

# API Development

## API Structure

```
app/controllers/api/
├── base_controller.rb       # Base for all API controllers
├── v1/                      # API version 1
│   ├── accounts/           # Account-scoped endpoints
│   │   ├── base_controller.rb
│   │   ├── conversations_controller.rb
│   │   ├── contacts_controller.rb
│   │   └── ...
│   └── ...
└── v2/                      # API version 2
```

## Base Controller Pattern

```ruby
# app/controllers/api/v1/accounts/base_controller.rb
class Api::V1::Accounts::BaseController < Api::BaseController
  include AuthenticateUser
  
  before_action :authenticate_user!
  before_action :set_current_account
  around_action :handle_with_exception

  private

  def set_current_account
    @current_account = Current.account = current_user.accounts.find(params[:account_id])
  end

  def check_authorization(model = nil)
    authorize(model || controller_name.classify.constantize)
  end
end
```

## Creating an API Endpoint

### 1. Define Routes

```ruby
# config/routes.rb
namespace :api, defaults: { format: :json } do
  namespace :v1 do
    resources :accounts, only: [] do
      resources :conversations do
        member do
          post :resolve
          post :toggle_status
        end
        resources :messages, only: [:index, :create]
      end
    end
  end
end
```

### 2. Create Controller

```ruby
# app/controllers/api/v1/accounts/conversations_controller.rb
class Api::V1::Accounts::ConversationsController < Api::V1::Accounts::BaseController
  before_action :set_conversation, only: [:show, :update, :resolve]
  before_action :check_authorization

  def index
    @conversations = ConversationFinder.new(
      Current.account,
      params
    ).perform
  end

  def show
    @messages = @conversation.messages.includes(:attachments)
  end

  def create
    @conversation = Conversations::CreateService.new(
      account: Current.account,
      params: conversation_params
    ).perform
    
    render json: @conversation, status: :created
  end

  def update
    @conversation.update!(conversation_params)
    render json: @conversation
  end

  def resolve
    Conversations::ResolveService.new(
      conversation: @conversation,
      user: current_user
    ).perform
    
    head :ok
  end

  private

  def set_conversation
    @conversation = Current.account.conversations.find(params[:id])
  end

  def conversation_params
    params.require(:conversation).permit(
      :inbox_id,
      :contact_id,
      :status,
      :assignee_id,
      :team_id,
      additional_attributes: {}
    )
  end
end
```

### 3. Create JSON View

```ruby
# app/views/api/v1/accounts/conversations/index.json.jbuilder
json.data do
  json.array! @conversations do |conversation|
    json.partial! 'api/v1/models/conversation', conversation: conversation
  end
end

json.meta do
  json.current_page @conversations.current_page
  json.total_pages @conversations.total_pages
  json.total_count @conversations.total_count
end
```

### 4. Create Partial

```ruby
# app/views/api/v1/models/_conversation.json.jbuilder
json.id conversation.id
json.account_id conversation.account_id
json.inbox_id conversation.inbox_id
json.status conversation.status
json.created_at conversation.created_at.to_i
json.updated_at conversation.updated_at.to_i

json.contact do
  json.partial! 'api/v1/models/contact', contact: conversation.contact
end if conversation.contact

json.assignee do
  json.partial! 'api/v1/models/user', user: conversation.assignee
end if conversation.assignee
```

## Authentication

### Token-based Auth

```ruby
# In controller
class Api::V1::Accounts::ConversationsController < Api::V1::Accounts::BaseController
  before_action :authenticate_user!
  
  # current_user is available after authentication
end
```

### API Key Auth (for Platform API)

```ruby
class PlatformController < ActionController::API
  include RequestExceptionHandler

  before_action :authenticate_platform_app!

  private

  def authenticate_platform_app!
    token = request.headers['api_access_token']
    @platform_app = PlatformApp.find_by(access_token: token)
    
    render_unauthorized('Invalid API key') unless @platform_app
  end
end
```

## Authorization with Pundit

```ruby
# app/policies/conversation_policy.rb
class ConversationPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    account_member? || assigned_to_user?
  end

  def update?
    account_administrator? || assigned_to_user?
  end

  def resolve?
    update?
  end

  private

  def assigned_to_user?
    record.assignee_id == user.id
  end

  def account_member?
    @account_user ||= user.account_users.find_by(account: record.account)
  end

  def account_administrator?
    account_member&.administrator?
  end
end
```

## Error Handling

```ruby
# Handled by RequestExceptionHandler concern
class Api::BaseController < ActionController::API
  include RequestExceptionHandler
end

# Errors are automatically formatted:
# { "error": "Record not found", "error_code": "not_found" }
```

### Custom Error Responses

```ruby
def create
  @conversation = build_conversation
  
  if @conversation.save
    render json: @conversation, status: :created
  else
    render json: { 
      errors: @conversation.errors.full_messages 
    }, status: :unprocessable_entity
  end
end
```

## Pagination

Use Kaminari for pagination:

```ruby
def index
  @conversations = Current.account
                         .conversations
                         .page(params[:page])
                         .per(params[:per_page] || 25)
end

# Response includes meta with pagination info
```

## Finders for Complex Queries

```ruby
# app/finders/conversation_finder.rb
class ConversationFinder
  attr_reader :account, :params

  def initialize(account, params)
    @account = account
    @params = params
  end

  def perform
    conversations = account.conversations
    conversations = filter_by_status(conversations)
    conversations = filter_by_inbox(conversations)
    conversations = filter_by_assignee(conversations)
    
    conversations.includes(:contact, :assignee)
                 .order(last_activity_at: :desc)
                 .page(params[:page])
  end

  private

  def filter_by_status(conversations)
    return conversations unless params[:status].present?
    
    conversations.where(status: params[:status])
  end

  def filter_by_inbox(conversations)
    return conversations unless params[:inbox_id].present?
    
    conversations.where(inbox_id: params[:inbox_id])
  end

  def filter_by_assignee(conversations)
    return conversations unless params[:assignee_id].present?
    
    conversations.where(assignee_id: params[:assignee_id])
  end
end
```

## Testing APIs

```ruby
# spec/requests/api/v1/accounts/conversations_spec.rb
require 'rails_helper'

RSpec.describe 'Conversations API', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'GET /api/v1/accounts/:account_id/conversations' do
    let!(:conversations) { create_list(:conversation, 3, account: account, inbox: inbox) }

    it 'returns conversations' do
      get "/api/v1/accounts/#{account.id}/conversations",
          headers: user.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      expect(json_response[:data].length).to eq(3)
    end

    context 'with status filter' do
      let!(:resolved) { create(:conversation, account: account, status: :resolved) }

      it 'filters by status' do
        get "/api/v1/accounts/#{account.id}/conversations",
            params: { status: 'resolved' },
            headers: user.create_new_auth_token,
            as: :json

        expect(json_response[:data].length).to eq(1)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/conversations' do
    let(:contact) { create(:contact, account: account) }
    let(:params) do
      {
        conversation: {
          inbox_id: inbox.id,
          contact_id: contact.id
        }
      }
    end

    it 'creates a conversation' do
      expect {
        post "/api/v1/accounts/#{account.id}/conversations",
             params: params,
             headers: user.create_new_auth_token,
             as: :json
      }.to change(Conversation, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end
end
```

## API Versioning

When making breaking changes, create a new version:

1. Create new namespace `api/v2/`
2. Keep v1 endpoints working for backward compatibility
3. Document deprecation timeline
