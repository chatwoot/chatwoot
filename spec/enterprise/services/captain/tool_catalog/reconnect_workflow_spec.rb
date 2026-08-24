require 'rails_helper'

RSpec.describe Captain::ToolCatalog::ReconnectWorkflow do
  subject(:reconnect_workflow) { described_class.new(account: account, initiated_by: admin, registry: registry) }

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

  it 'relinks disconnected tools to the replacement account connection' do
    old_hook = create(:integrations_hook, account: account, app_id: 'example', settings: { scope: 'customers:read' })
    installation = Captain::ToolCatalog::InstallationWorkflow.new(
      account: account,
      initiated_by: admin,
      registry: registry
    ).perform(provider_key: 'example', templates: templates)
    tool = Captain::CustomTool.find(installation.resulting_tool_ids.sole)
    old_hook.destroy!
    replacement_hook = create(:integrations_hook, account: account, app_id: 'example', settings: { scope: 'customers:read' })

    reconnect = reconnect_workflow.perform(provider_key: 'example')

    expect(reconnect).to be_completed
    expect(reconnect).to be_workflow_reconnect
    expect(tool.reload.integration_hook).to eq(replacement_hook)
  end

  it 'keeps tools unchanged while a replacement connection is unavailable' do
    old_hook = create(:integrations_hook, account: account, app_id: 'example', settings: { scope: 'customers:read' })
    installation = Captain::ToolCatalog::InstallationWorkflow.new(
      account: account,
      initiated_by: admin,
      registry: registry
    ).perform(provider_key: 'example', templates: templates)
    tool = Captain::CustomTool.find(installation.resulting_tool_ids.sole)
    old_hook.destroy!

    reconnect = reconnect_workflow.perform(provider_key: 'example')

    expect(reconnect).to be_awaiting_connection
    expect(tool.reload.integration_hook).to be_nil
  end
end
