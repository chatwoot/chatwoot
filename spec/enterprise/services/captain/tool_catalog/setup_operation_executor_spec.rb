require 'rails_helper'

RSpec.describe Captain::ToolCatalog::SetupOperationExecutor do
  let(:account) { create(:account) }

  before do
    account.enable_features!('captain_tool_catalog')
    allow(Chatwoot).to receive(:encryption_configured?).and_return(true)
  end

  it 'returns only bounded Slack channel selector fields' do
    create(
      :integrations_hook,
      account: account,
      app_id: 'slack',
      access_token: 'slack-secret',
      status: 'disabled',
      settings: { catalog_connected: true, scope: 'channels:read,groups:read' }
    )
    request = stub_request(:get, %r{https://slack.com/api/conversations.list})
              .with(headers: { 'Authorization' => 'Bearer slack-secret' })
              .to_return(
                status: 200,
                body: {
                  ok: true,
                  channels: [
                    { id: 'C012SUPPORT', name: 'support', is_private: false, topic: { value: 'private topic' } }
                  ],
                  response_metadata: { next_cursor: 'private-cursor' }
                }.to_json
              )

    result = described_class.new(account: account).perform(
      provider_key: 'slack',
      operation_key: 'list_channels'
    )

    expect(request).to have_been_requested
    expect(result).to eq(
      'options' => [{ 'id' => 'C012SUPPORT', 'name' => 'support', 'is_private' => false }]
    )
    expect(result.to_json).not_to include('private topic', 'private-cursor', 'slack-secret')
  end

  it 'projects Linear teams and rejects unreviewed setup operations' do
    create(
      :integrations_hook,
      :linear,
      account: account,
      access_token: 'linear-secret',
      settings: { scope: 'read,write' }
    )
    stub_request(:post, 'https://api.linear.app/graphql').to_return(
      status: 200,
      body: {
        data: {
          teams: {
            nodes: [{ id: 'team-1', name: 'Support', private_field: 'hidden' }]
          }
        }
      }.to_json
    )

    result = described_class.new(account: account).perform(
      provider_key: 'linear',
      operation_key: 'list_teams'
    )

    expect(result).to eq('options' => [{ 'id' => 'team-1', 'name' => 'Support' }])
    expect do
      described_class.new(account: account).perform(provider_key: 'linear', operation_key: 'issue_create')
    end.to raise_error(Captain::ToolCatalog::WorkflowError) { |error| expect(error.code).to eq('setup_operation_not_found') }
  end

  it 'requires a connected provider with sufficient setup scopes' do
    expect do
      described_class.new(account: account).perform(provider_key: 'slack', operation_key: 'list_channels')
    end.to raise_error(Captain::ToolCatalog::WorkflowError) { |error| expect(error.code).to eq('setup_connection_required') }
  end
end
