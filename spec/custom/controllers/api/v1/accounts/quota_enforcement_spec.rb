require 'rails_helper'

RSpec.describe 'Quota enforcement on account APIs', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  # The control plane's service identity: an administrator whose account_user is
  # itself platform-managed. Only this identity may set the `platform_managed`
  # exemption flag (docs/fork/adr/0005).
  let(:platform_admin) do
    user = create(:user, account: account, role: :administrator)
    account.account_users.find_by(user_id: user.id).update!(platform_managed: true)
    user
  end

  shared_examples 'a quota guarded create endpoint' do
    it 'rejects creation at the cap with the shared 402 contract' do
      account.update!(limits: { resource => 1 })
      existing_record

      post url, params: payload, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:payment_required)
      body = response.parsed_body
      expect(body['error']).to include('Account limit exceeded')
      expect(body['error_code']).to eq('quota_exceeded')
      expect(body['resource']).to eq(resource.to_s)
      expect(body['current']).to eq(1)
      expect(body['limit']).to eq(1)
    end

    it 'allows creation below the cap' do
      account.update!(limits: { resource => 2 })
      existing_record

      post url, params: payload, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/teams' do
    let(:resource) { :teams }
    let(:url) { "/api/v1/accounts/#{account.id}/teams" }
    let(:payload) { { name: 'Quota Team' } }
    let(:existing_record) { create(:team, account: account) }

    it_behaves_like 'a quota guarded create endpoint'
  end

  describe 'POST /api/v1/accounts/{account.id}/webhooks' do
    let(:resource) { :webhooks }
    let(:url) { "/api/v1/accounts/#{account.id}/webhooks" }
    let(:payload) { { webhook: { url: 'https://example.com/hooks', subscriptions: ['message_created'] } } }
    let(:existing_record) { create(:webhook, account: account) }

    it_behaves_like 'a quota guarded create endpoint'
  end

  describe 'POST /api/v1/accounts/{account.id}/agent_bots' do
    let(:resource) { :agent_bots }
    let(:url) { "/api/v1/accounts/#{account.id}/agent_bots" }
    let(:payload) { { name: 'Quota Bot', outgoing_url: 'https://example.com/bot' } }
    let(:existing_record) { create(:agent_bot, account: account) }

    it_behaves_like 'a quota guarded create endpoint'
  end

  describe 'POST /api/v1/accounts/{account.id}/labels' do
    let(:resource) { :labels }
    let(:url) { "/api/v1/accounts/#{account.id}/labels" }
    let(:payload) { { label: { title: 'quota_label', color: '#FF0000' } } }
    let(:existing_record) { create(:label, account: account) }

    it_behaves_like 'a quota guarded create endpoint'
  end

  describe 'POST /api/v1/accounts/{account.id}/custom_attribute_definitions' do
    let(:resource) { :custom_attribute_definitions }
    let(:url) { "/api/v1/accounts/#{account.id}/custom_attribute_definitions" }
    let(:payload) do
      {
        custom_attribute_definition: {
          attribute_display_name: 'Developer ID',
          attribute_key: 'developer_id',
          attribute_model: 'contact_attribute',
          attribute_display_type: 'text'
        }
      }
    end
    let(:existing_record) { create(:custom_attribute_definition, account: account) }

    it_behaves_like 'a quota guarded create endpoint'
  end

  describe 'POST /api/v1/accounts/{account.id}/automation_rules' do
    let(:resource) { :automation_rules }
    let(:url) { "/api/v1/accounts/#{account.id}/automation_rules" }
    let(:payload) do
      {
        name: 'Quota Rule',
        event_name: 'conversation_created',
        conditions: [{ attribute_key: 'status', filter_operator: 'equal_to', values: ['open'], query_operator: nil }],
        actions: [{ action_name: 'add_label', action_params: ['support'] }]
      }
    end
    let(:existing_record) { create(:automation_rule, account: account) }

    it_behaves_like 'a quota guarded create endpoint'
  end

  describe 'POST /api/v1/accounts/{account.id}/automation_rules/{id}/clone' do
    it 'rejects cloning at the cap with the shared 402 contract' do
      account.update!(limits: { automation_rules: 1 })
      rule = create(:automation_rule, account: account)

      post "/api/v1/accounts/#{account.id}/automation_rules/#{rule.id}/clone",
           headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:payment_required)
      expect(response.parsed_body['error_code']).to eq('quota_exceeded')
    end

    it 'allows cloning below the cap' do
      account.update!(limits: { automation_rules: 2 })
      rule = create(:automation_rule, account: account)

      post "/api/v1/accounts/#{account.id}/automation_rules/#{rule.id}/clone",
           headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(account.automation_rules.count).to eq 2
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/integrations/hooks' do
    let(:resource) { :integrations }
    let(:url) { "/api/v1/accounts/#{account.id}/integrations/hooks" }
    let(:inbox) { create(:inbox, account: account) }
    let(:payload) do
      { app_id: 'dialogflow', inbox_id: inbox.id,
        settings: { project_id: 'xx', credentials: { test: 'test' }, region: 'europe-west1' } }
    end
    let(:existing_record) { create(:integrations_hook, account: account) }

    it_behaves_like 'a quota guarded create endpoint'
  end

  describe 'platform-managed creates bypass the controller quota guard (ADR-0005)' do
    it 'allows a platform-managed webhook at the cap and persists the flag' do
      account.update!(limits: { webhooks: 1 })
      create(:webhook, account: account)

      post "/api/v1/accounts/#{account.id}/webhooks",
           params: { webhook: { url: 'https://example.com/platform', subscriptions: ['message_created'], platform_managed: true } },
           headers: platform_admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(account.webhooks.find_by(url: 'https://example.com/platform').platform_managed).to be true
    end

    it 'allows a platform-managed agent bot at the cap and persists the flag' do
      account.update!(limits: { agent_bots: 1 })
      create(:agent_bot, account: account)

      post "/api/v1/accounts/#{account.id}/agent_bots",
           params: { name: 'System AI', outgoing_url: 'https://example.com/bot', platform_managed: true },
           headers: platform_admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(account.agent_bots.find_by(name: 'System AI').platform_managed).to be true
    end

    it 'still blocks a tenant (non-managed) webhook at the cap' do
      account.update!(limits: { webhooks: 1 })
      create(:webhook, account: account)

      post "/api/v1/accounts/#{account.id}/webhooks",
           params: { webhook: { url: 'https://example.com/tenant', subscriptions: ['message_created'] } },
           headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:payment_required)
      expect(response.parsed_body['error_code']).to eq('quota_exceeded')
    end
  end

  # Regression for the platform_managed privilege-escalation loophole: a tenant
  # admin is NOT a platform actor, so a tenant-supplied `platform_managed: true`
  # must be stripped — the flag is ignored and the resource still counts against
  # the plan (docs/fork/adr/0005).
  describe 'tenant admins cannot self-grant the platform-managed exemption' do
    it 'blocks a webhook even when the tenant admin supplies platform_managed: true' do
      account.update!(limits: { webhooks: 1 })
      create(:webhook, account: account)

      post "/api/v1/accounts/#{account.id}/webhooks",
           params: { webhook: { url: 'https://example.com/sneaky', subscriptions: ['message_created'], platform_managed: true } },
           headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:payment_required)
      expect(response.parsed_body['error_code']).to eq('quota_exceeded')
    end

    it 'strips the flag on a below-cap webhook so it still counts against the plan' do
      account.update!(limits: { webhooks: 5 })

      post "/api/v1/accounts/#{account.id}/webhooks",
           params: { webhook: { url: 'https://example.com/counted', subscriptions: ['message_created'], platform_managed: true } },
           headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(account.webhooks.find_by(url: 'https://example.com/counted').platform_managed).to be false
    end

    it 'blocks an agent bot even when the tenant admin supplies platform_managed: true' do
      account.update!(limits: { agent_bots: 1 })
      create(:agent_bot, account: account)

      post "/api/v1/accounts/#{account.id}/agent_bots",
           params: { name: 'Sneaky Bot', outgoing_url: 'https://example.com/bot', platform_managed: true },
           headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:payment_required)
      expect(response.parsed_body['error_code']).to eq('quota_exceeded')
    end

    it 'strips the flag on a below-cap agent bot so it still counts against the plan' do
      account.update!(limits: { agent_bots: 5 })

      post "/api/v1/accounts/#{account.id}/agent_bots",
           params: { name: 'Counted Bot', outgoing_url: 'https://example.com/bot', platform_managed: true },
           headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(account.agent_bots.find_by(name: 'Counted Bot').platform_managed).to be false
    end
  end
end
