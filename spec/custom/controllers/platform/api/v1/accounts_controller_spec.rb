require 'rails_helper'

RSpec.describe 'Platform Accounts API (fork quota provisioning)', type: :request do
  let(:platform_app) { create(:platform_app) }

  it 'provisions an account with fork quota limits' do
    post '/platform/api/v1/accounts',
         params: { name: 'Tenant', limits: { agents: 3, teams: 2, inboxes: 2, agent_bots: 1, webhooks: 2 } },
         headers: { api_access_token: platform_app.access_token.token }, as: :json

    expect(response).to have_http_status(:success)
    account = Account.find(response.parsed_body['id'])
    expect(account.usage_limits[:agents]).to eq 3
    expect(account.usage_limits[:teams]).to eq 2
    expect(account.usage_limits[:agent_bots]).to eq 1
  end

  it 'updates quota limits on plan changes' do
    account = create(:account)
    platform_app.platform_app_permissibles.create!(permissible: account)

    patch "/platform/api/v1/accounts/#{account.id}",
          params: { limits: { teams: 5, integrations: 3 } },
          headers: { api_access_token: platform_app.access_token.token }, as: :json

    expect(response).to have_http_status(:success)
    expect(account.reload.usage_limits[:teams]).to eq 5
    expect(account.usage_limits[:integrations]).to eq 3
  end

  it 'rejects unknown limit keys' do
    post '/platform/api/v1/accounts',
         params: { name: 'Tenant', limits: { bogus: 1 } },
         headers: { api_access_token: platform_app.access_token.token }, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
  end

  describe 'custom_attributes merge-patch on update' do
    let(:account) do
      create(:account, custom_attributes: { 'marked_for_deletion_at' => '2026-07-17T00:00:00Z', 'plan_name' => 'startups' })
    end

    before { platform_app.platform_app_permissibles.create!(permissible: account) }

    it 'preserves keys omitted from a sparse patch (agentic usage writeback safety)' do
      patch "/platform/api/v1/accounts/#{account.id}",
            params: { custom_attributes: { agentic_ai_usage: 1234 } },
            headers: { api_access_token: platform_app.access_token.token }, as: :json

      expect(response).to have_http_status(:success)
      expect(account.reload.custom_attributes).to eq(
        'marked_for_deletion_at' => '2026-07-17T00:00:00Z',
        'plan_name' => 'startups',
        'agentic_ai_usage' => 1234
      )
    end

    it 'deletes a key on an explicit null' do
      patch "/platform/api/v1/accounts/#{account.id}",
            params: { custom_attributes: { marked_for_deletion_at: nil } },
            headers: { api_access_token: platform_app.access_token.token }, as: :json

      expect(response).to have_http_status(:success)
      expect(account.reload.custom_attributes).to eq('plan_name' => 'startups')
    end
  end
end
