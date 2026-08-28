require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::ToolCatalogConnections', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:params) do
    {
      connection: {
        provider_key: 'slack',
        templates: [{ template_key: 'send_message_to_channel', template_version: '1.0.0' }]
      }
    }
  end

  before do
    account.enable_features!('captain_tool_catalog')
    allow(Chatwoot).to receive(:encryption_configured?).and_return(true)
  end

  it 'creates an administrator-only resumable connection session without accepting scopes from the client' do
    post "/api/v1/accounts/#{account.id}/captain/tool_catalog/connections",
         params: params.deep_merge(connection: { scopes: ['admin'] }),
         headers: admin.create_new_auth_token,
         as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.dig('payload', 'workflow_kind')).to eq('connect')
    expect(response.parsed_body.dig('payload', 'connection', 'missing_scopes')).to contain_exactly(
      'channels:join', 'channels:read', 'chat:write', 'groups:read'
    )
    expect(response.body).not_to include('admin')
  end

  it 'rejects non-administrators' do
    post "/api/v1/accounts/#{account.id}/captain/tool_catalog/connections",
         params: params,
         headers: agent.create_new_auth_token,
         as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end
