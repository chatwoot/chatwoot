require 'rails_helper'

RSpec.describe Captain::ToolCatalog::UpdateWorkflow do
  subject(:update_workflow) { described_class.new(account: account, initiated_by: admin, registry: registry) }

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

  it 'updates selected snapshots atomically and records the resulting tools' do
    hook = create(:integrations_hook, account: account, app_id: 'example', settings: { scope: 'customers:read' })
    tool = create(
      :captain_custom_tool,
      :catalog,
      account: account,
      provider_key: 'example',
      template_key: 'get_current_customer',
      template_version: '0.9.0',
      title: 'Old title'
    )

    installation = update_workflow.perform(provider_key: 'example', templates: templates)

    expect(installation).to be_completed
    expect(installation).to be_workflow_update
    expect(installation.resulting_tool_ids).to eq([tool.id])
    expect(tool.reload).to have_attributes(
      title: 'Get current customer',
      template_version: '1.0.0',
      integration_hook_id: hook.id
    )
  end

  it 'does not change a snapshot while broader scopes are missing' do
    create(:integrations_hook, account: account, app_id: 'example', settings: {})
    tool = create(
      :captain_custom_tool,
      :catalog,
      account: account,
      provider_key: 'example',
      template_key: 'get_current_customer',
      template_version: '0.9.0'
    )

    installation = update_workflow.perform(provider_key: 'example', templates: templates)

    expect(installation).to be_awaiting_connection
    expect(tool.reload.template_version).to eq('0.9.0')
  end

  it 'fails without mutating another provider or account tool' do
    other_tool = create(:captain_custom_tool, :catalog, provider_key: 'example', template_key: 'get_current_customer')

    expect do
      update_workflow.perform(provider_key: 'example', templates: templates)
    end.to raise_error(Captain::ToolCatalog::WorkflowError) { |error| expect(error.code).to eq('installed_tool_not_found') }

    expect(other_tool.reload.template_version).to eq('1.0.0')
    expect(account.captain_tool_catalog_installations.sole.error_code).to eq('installed_tool_not_found')
  end
end
