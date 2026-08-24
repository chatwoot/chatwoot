require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::ToolCatalogSetupOperations', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:executor) { instance_double(Captain::ToolCatalog::SetupOperationExecutor) }

  before do
    account.enable_features!('captain_tool_catalog')
    allow(Captain::ToolCatalog::SetupOperationExecutor).to receive(:new).with(account: account).and_return(executor)
    allow(executor).to receive(:perform)
  end

  it 'executes an allowlisted setup selector for an administrator' do
    allow(executor).to receive(:perform).and_return('options' => [{ 'id' => 'team-1', 'name' => 'Support' }])

    post "/api/v1/accounts/#{account.id}/captain/tool_catalog/linear/setup/list_teams",
         params: { setup: { arguments: {} } },
         headers: admin.create_new_auth_token,
         as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq('payload' => { 'options' => [{ 'id' => 'team-1', 'name' => 'Support' }] })
    expect(executor).to have_received(:perform).with(
      provider_key: 'linear',
      operation_key: 'list_teams',
      arguments: {}
    )
  end

  it 'rejects non-administrators before provider access' do
    post "/api/v1/accounts/#{account.id}/captain/tool_catalog/linear/setup/list_teams",
         headers: agent.create_new_auth_token,
         as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(executor).not_to have_received(:perform)
  end
end
