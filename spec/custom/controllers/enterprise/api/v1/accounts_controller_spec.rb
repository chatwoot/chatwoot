require 'rails_helper'

RSpec.describe 'Enterprise Accounts API (fork quota limits)', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  before do
    # Deterministic self-hosted env regardless of GlobalConfig cache state
    # left behind by other spec files in the same process.
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
  end

  describe 'GET /enterprise/api/v1/accounts/{account.id}/limits' do
    it 'serves limits on self-hosted installs with every quota resource' do
      account.update!(limits: { teams: 2 })
      create(:team, account: account)

      get "/enterprise/api/v1/accounts/#{account.id}/limits",
          headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      limits = response.parsed_body['limits']
      expect(limits['teams']).to eq('allowed' => 2, 'consumed' => 1)
      expect(limits.keys).to include('agents', 'inboxes', 'webhooks', 'agent_bots', 'labels',
                                     'custom_attribute_definitions', 'automation_rules', 'integrations')
    end

    it 'marks unconfigured resources as unlimited via a null allowance' do
      get "/enterprise/api/v1/accounts/#{account.id}/limits",
          headers: admin.create_new_auth_token, as: :json

      expect(response.parsed_body['limits']['labels']).to eq('allowed' => nil, 'consumed' => 0)
    end

    it 'surfaces the externally-enforced agentic_ai limit when a cap is set' do
      account.update!(limits: { agentic_ai: 500 }, custom_attributes: { agentic_ai_usage: 500 })

      get "/enterprise/api/v1/accounts/#{account.id}/limits",
          headers: admin.create_new_auth_token, as: :json

      expect(response.parsed_body['limits']['agentic_ai']).to eq('allowed' => 500, 'consumed' => 500)
    end

    it 'omits agentic_ai when no cap is provisioned' do
      get "/enterprise/api/v1/accounts/#{account.id}/limits",
          headers: admin.create_new_auth_token, as: :json

      expect(response.parsed_body['limits']).not_to have_key('agentic_ai')
    end

    it 'requires authentication' do
      get "/enterprise/api/v1/accounts/#{account.id}/limits", as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /enterprise/api/v1/accounts/{account.id}/toggle_deletion' do
    it 'stays cloud-gated on self-hosted installs' do
      post "/enterprise/api/v1/accounts/#{account.id}/toggle_deletion",
           params: { action_type: 'delete' },
           headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
