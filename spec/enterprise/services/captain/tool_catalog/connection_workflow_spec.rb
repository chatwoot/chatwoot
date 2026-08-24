require 'rails_helper'

RSpec.describe Captain::ToolCatalog::ConnectionWorkflow do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:pack) do
    Captain::ToolCatalog::ProviderPackCompiler.new(
      pack_path: Rails.root.join('enterprise/config/captain/tool_catalog/providers/slack')
    ).compile
  end
  let(:registry) { instance_double(Captain::ToolCatalog::ProviderPackRegistry, find: pack) }

  before do
    account.enable_features!('captain_tool_catalog')
    allow(Chatwoot).to receive(:encryption_configured?).and_return(true)
  end

  it 'creates a scope-bound OAuth session before setup configuration is available' do
    installation = described_class.new(account: account, initiated_by: admin, registry: registry).perform(
      provider_key: 'slack',
      templates: [{ template_key: 'send_message_to_channel', template_version: '1.0.0' }]
    )

    expect(installation).to have_attributes(
      workflow_kind: 'connect',
      provider_key: 'slack',
      status: 'awaiting_connection',
      selected_templates: [
        {
          'template_key' => 'send_message_to_channel',
          'template_version' => '1.0.0',
          'configuration' => {}
        }
      ]
    )
    expect(installation.attributes.to_json).not_to include('access_token', 'credential')
  end
end
