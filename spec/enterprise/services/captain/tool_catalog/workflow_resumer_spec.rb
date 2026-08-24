require 'rails_helper'

RSpec.describe Captain::ToolCatalog::WorkflowResumer do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:pack) do
    Captain::ToolCatalog::ProviderPackCompiler.new(
      pack_path: Rails.root.join('spec/fixtures/captain/tool_catalog/providers/example')
    ).compile
  end
  let(:registry) { instance_double(Captain::ToolCatalog::ProviderPackRegistry, find: pack) }
  let(:templates) do
    [{ 'template_key' => 'get_current_customer', 'template_version' => '1.0.0', 'configuration' => {} }]
  end

  before do
    account.enable_features!('captain_tool_catalog')
    allow(Chatwoot).to receive(:encryption_configured?).and_return(true)
  end

  it 'dispatches a persisted session to its workflow after connection completion' do
    installation = Captain::ToolCatalog::InstallationWorkflow.new(
      account: account,
      initiated_by: admin,
      registry: registry
    ).perform(provider_key: 'example', templates: templates)
    create(:integrations_hook, account: account, app_id: 'example', settings: { scope: 'customers:read' })

    result = described_class.new(registry: registry).perform(installation)

    expect(result).to be_completed
    expect(result.id).to eq(installation.id)
  end
end
