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
end
