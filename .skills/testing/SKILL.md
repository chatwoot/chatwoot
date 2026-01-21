---
name: testing
description: Write and run tests for Chatwoot using RSpec for Ruby and Vitest for JavaScript. Use this skill when creating test files, running test suites, debugging test failures, or following testing best practices.
metadata:
  author: chatwoot
  version: "1.0"
---

# Testing in Chatwoot

## Running Tests

### Ruby (RSpec)

```bash
# Initialize rbenv first
eval "$(rbenv init -)"

# Run all specs
bundle exec rspec

# Run specific file
bundle exec rspec spec/models/conversation_spec.rb

# Run specific test by line number
bundle exec rspec spec/models/conversation_spec.rb:42

# Run with verbose output
bundle exec rspec spec/models/conversation_spec.rb --format documentation

# Run specs matching a pattern
bundle exec rspec --example "creates a conversation"
```

### JavaScript (Vitest)

```bash
# Run all tests
pnpm test

# Watch mode
pnpm test:watch

# Run specific file
pnpm test -- conversation.spec.js
```

## Ruby Test Structure

### Model Specs

```ruby
# spec/models/conversation_spec.rb
require 'rails_helper'

RSpec.describe Conversation do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to belong_to(:contact) }
    it { is_expected.to have_many(:messages).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:account_id) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:status).with_values(open: 0, resolved: 1, pending: 2) }
  end

  describe 'scopes' do
    describe '.recent' do
      it 'orders by created_at desc' do
        old = create(:conversation, created_at: 1.day.ago)
        new = create(:conversation, created_at: 1.hour.ago)

        expect(described_class.recent).to eq([new, old])
      end
    end
  end

  describe '#resolve!' do
    let(:conversation) { create(:conversation, status: :open) }

    it 'changes status to resolved' do
      expect { conversation.resolve! }
        .to change { conversation.status }
        .from('open')
        .to('resolved')
    end
  end
end
```

### Service Specs

```ruby
# spec/services/conversations/resolve_service_spec.rb
require 'rails_helper'

RSpec.describe Conversations::ResolveService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account, status: :open) }

  subject(:service) do
    described_class.new(conversation: conversation, user: user)
  end

  describe '#perform' do
    it 'resolves the conversation' do
      service.perform
      
      expect(conversation.reload).to be_resolved
    end

    it 'creates an activity message' do
      expect { service.perform }
        .to change { conversation.messages.activity.count }
        .by(1)
    end

    context 'when conversation is already resolved' do
      let(:conversation) { create(:conversation, account: account, status: :resolved) }

      it 'does not change the conversation' do
        expect { service.perform }
          .not_to change { conversation.reload.updated_at }
      end
    end
  end
end
```

### Request Specs (API)

```ruby
# spec/requests/api/v1/accounts/conversations_spec.rb
require 'rails_helper'

RSpec.describe 'Conversations API', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'GET /api/v1/accounts/:account_id/conversations' do
    let!(:conversations) { create_list(:conversation, 3, account: account) }

    context 'when authenticated' do
      it 'returns conversations' do
        get "/api/v1/accounts/#{account.id}/conversations",
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response[:data].size).to eq(3)
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/conversations", as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/conversations' do
    let(:contact) { create(:contact, account: account) }
    let(:valid_params) do
      { conversation: { inbox_id: inbox.id, contact_id: contact.id } }
    end

    it 'creates a conversation' do
      expect {
        post "/api/v1/accounts/#{account.id}/conversations",
             params: valid_params,
             headers: user.create_new_auth_token,
             as: :json
      }.to change(Conversation, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end
end
```

## JavaScript Test Structure

### Component Tests

```javascript
// spec/javascript/dashboard/components/ConversationCard.spec.js
import { describe, it, expect, vi } from 'vitest';
import { mount } from '@vue/test-utils';
import ConversationCard from 'dashboard/components/ConversationCard.vue';

describe('ConversationCard', () => {
  const defaultProps = {
    conversation: {
      id: 1,
      status: 'open',
      contact: { name: 'John Doe' },
      messages: [{ content: 'Hello' }],
    },
  };

  const createWrapper = (props = {}) => {
    return mount(ConversationCard, {
      props: { ...defaultProps, ...props },
      global: {
        mocks: {
          $t: (key) => key,
        },
      },
    });
  };

  it('renders conversation contact name', () => {
    const wrapper = createWrapper();
    
    expect(wrapper.text()).toContain('John Doe');
  });

  it('emits select event on click', async () => {
    const wrapper = createWrapper();
    
    await wrapper.trigger('click');
    
    expect(wrapper.emitted('select')).toBeTruthy();
    expect(wrapper.emitted('select')[0]).toEqual([1]);
  });

  describe('when conversation is resolved', () => {
    it('shows resolved badge', () => {
      const wrapper = createWrapper({
        conversation: {
          ...defaultProps.conversation,
          status: 'resolved',
        },
      });

      expect(wrapper.find('[data-testid="resolved-badge"]').exists()).toBe(true);
    });
  });
});
```

### Composable Tests

```javascript
// spec/javascript/dashboard/composables/useConversation.spec.js
import { describe, it, expect } from 'vitest';
import { useConversation } from 'dashboard/composables/useConversation';

describe('useConversation', () => {
  it('returns conversation data', () => {
    const { isResolved } = useConversation({ status: 'resolved' });
    
    expect(isResolved.value).toBe(true);
  });
});
```

## Factories

Use FactoryBot for test data:

```ruby
# spec/factories/conversations.rb
FactoryBot.define do
  factory :conversation do
    account
    inbox
    contact
    status { :open }
    
    trait :resolved do
      status { :resolved }
      resolved_at { Time.current }
    end

    trait :with_messages do
      after(:create) do |conversation|
        create_list(:message, 3, conversation: conversation)
      end
    end
  end
end

# Usage
create(:conversation)
create(:conversation, :resolved)
create(:conversation, :with_messages)
```

## Test Helpers

### Environment Variables

Use `with_modified_env` instead of stubbing ENV:

```ruby
# ✅ Correct
it 'uses custom config' do
  with_modified_env(FEATURE_FLAG: 'true') do
    expect(service.feature_enabled?).to be(true)
  end
end

# ❌ Wrong - Don't stub ENV directly
it 'uses custom config' do
  allow(ENV).to receive(:[]).with('FEATURE_FLAG').and_return('true')
end
```

### Error Class Assertions

In parallel/reloading environments, compare class names:

```ruby
# ✅ Correct
it 'raises not found error' do
  expect { service.perform }
    .to raise_error { |e| expect(e.class.name).to eq('CustomExceptions::NotFound') }
end

# ❌ May fail in parallel tests
it 'raises not found error' do
  expect { service.perform }.to raise_error(CustomExceptions::NotFound)
end
```

## Best Practices

1. **One assertion per test when possible**
2. **Use descriptive test names**
3. **Avoid testing implementation details**
4. **Keep tests fast - mock external services**
5. **Use `let` for lazy evaluation**
6. **Use `let!` when you need eager evaluation**
7. **Group related tests with `context`**

```ruby
describe '#perform' do
  context 'when valid input' do
    it 'succeeds' do
      # test success case
    end
  end

  context 'when invalid input' do
    it 'raises an error' do
      # test error case
    end
  end
end
```

## Enterprise Tests

Add Enterprise-specific specs under `spec/enterprise/`:

```ruby
# spec/enterprise/services/conversations/premium_resolve_service_spec.rb
require 'rails_helper'

RSpec.describe Conversations::PremiumResolveService do
  # Enterprise-specific tests
end
```
