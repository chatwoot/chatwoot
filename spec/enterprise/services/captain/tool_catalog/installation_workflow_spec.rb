require 'rails_helper'

RSpec.describe Captain::ToolCatalog::InstallationWorkflow do
  subject(:workflow) { described_class.new(account: account, initiated_by: admin, registry: registry) }

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

  it 'atomically installs an immutable snapshot against one reusable connection' do
    hook = create(:integrations_hook, account: account, app_id: 'example', access_token: 'provider-secret', settings: { scope: 'customers:read' })

    installation = workflow.perform(provider_key: 'example', templates: templates)
    tool = account.captain_custom_tools.catalog.sole

    expect(installation).to be_completed
    expect(installation).to be_workflow_install
    expect(installation.resulting_tool_ids).to eq([tool.id])
    expect(tool).to have_attributes(
      provider_key: 'example',
      template_key: 'get_current_customer',
      template_version: '1.0.0',
      integration_hook_id: hook.id,
      endpoint_url: nil,
      auth_config: {}
    )
    expect(tool.definition.fetch('operations').pluck('key')).to eq(['find_customer'])
    expect(tool.definition.to_json).not_to include('provider-secret')
  end

  it 'emits sanitized workflow funnel events' do
    create(:integrations_hook, account: account, app_id: 'example', settings: { scope: 'customers:read' })
    events = []
    subscription = ActiveSupport::Notifications.subscribe(Captain::ToolCatalog::BaseWorkflow::EVENT_NAME) do |event|
      events << event.payload
    end

    workflow.perform(provider_key: 'example', templates: templates)

    expect(events).to contain_exactly(
      include(provider: 'example', workflow: 'install', status: 'pending', template_count: 1),
      include(provider: 'example', workflow: 'install', status: 'completed', resulting_tool_count: 1)
    )
    expect(events.to_json).not_to include('provider-secret', 'customers:read')
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription) if subscription
  end

  it 'returns an existing duplicate unchanged' do
    hook = create(:integrations_hook, account: account, app_id: 'example', settings: { scope: 'customers:read' })
    first_installation = workflow.perform(provider_key: 'example', templates: templates)
    tool = Captain::CustomTool.find(first_installation.resulting_tool_ids.sole)
    original_updated_at = tool.updated_at

    second_installation = workflow.perform(provider_key: 'example', templates: templates)

    expect(second_installation).to be_completed
    expect(second_installation.resulting_tool_ids).to eq([tool.id])
    expect(account.captain_custom_tools.catalog.count).to eq(1)
    expect(tool.reload.updated_at).to eq(original_updated_at)
    expect(second_installation.integration_hook).to eq(hook)
  end

  it 'persists a resumable connection-required state without creating tools' do
    installation = workflow.perform(provider_key: 'example', templates: templates)

    expect(installation).to be_awaiting_connection
    expect(installation.selected_templates).to eq(templates)
    expect(account.captain_custom_tools.catalog).to be_empty
  end

  it 'requires every effective scope before installing' do
    create(:integrations_hook, account: account, app_id: 'example', settings: { scope: 'customers:write' })

    installation = workflow.perform(provider_key: 'example', templates: templates)

    expect(installation).to be_awaiting_connection
    expect(account.captain_custom_tools.catalog).to be_empty
  end

  it 'continues with the model plaintext fallback when credential encryption is unavailable' do
    allow(Chatwoot).to receive(:encryption_configured?).and_return(false)

    installation = workflow.perform(provider_key: 'example', templates: templates)

    expect(installation).to be_awaiting_connection
    expect(installation.error_code).to be_nil
  end

  it 'rejects stale versions before creating a session' do
    templates.first['template_version'] = '0.9.0'

    expect do
      workflow.perform(provider_key: 'example', templates: templates)
    end.to raise_error(Captain::ToolCatalog::WorkflowError) { |error| expect(error.code).to eq('template_version_changed') }

    expect(account.captain_tool_catalog_installations).to be_empty
  end

  it 'enforces capacity before waiting for a connection' do
    allow(Captain::CustomTool).to receive(:limit_for).with(account).and_return(0)

    expect do
      workflow.perform(provider_key: 'example', templates: templates)
    end.to raise_error(Captain::ToolCatalog::WorkflowError) { |error| expect(error.code).to eq('tool_capacity_exceeded') }

    expect(account.captain_tool_catalog_installations.sole.error_code).to eq('tool_capacity_exceeded')
  end

  it 'rolls back every new tool when any snapshot is invalid' do
    invalid_pack = pack.deep_dup
    invalid_template = invalid_pack.fetch('templates').first.deep_dup.merge(
      'key' => 'invalid_customer',
      'stable_name' => 'example_invalid_customer',
      'output_schema' => {}
    )
    invalid_pack.fetch('templates') << invalid_template
    allow(registry).to receive(:find).and_return(invalid_pack)
    create(:integrations_hook, account: account, app_id: 'example', settings: { scope: 'customers:read' })
    selections = templates + [{ 'template_key' => 'invalid_customer', 'template_version' => '1.0.0', 'configuration' => {} }]

    expect do
      workflow.perform(provider_key: 'example', templates: selections)
    end.to raise_error(ActiveRecord::RecordInvalid)

    expect(account.captain_custom_tools.catalog).to be_empty
    expect(account.captain_tool_catalog_installations.sole).to have_attributes(status: 'failed', error_code: 'workflow_failed')
  end

  describe '#resume' do
    it 'completes the same session after the required connection appears' do
      installation = workflow.perform(provider_key: 'example', templates: templates)
      create(:integrations_hook, account: account, app_id: 'example', settings: { scope: 'customers:read' })

      resumed = workflow.resume(installation)

      expect(resumed.id).to eq(installation.id)
      expect(resumed).to be_completed
      expect(resumed.resulting_tool_ids).to contain_exactly(account.captain_custom_tools.catalog.sole.id)
    end

    it 'expires an old session instead of resuming it' do
      installation = workflow.perform(provider_key: 'example', templates: templates)
      installation.update!(expires_at: 1.minute.ago)

      expect do
        workflow.resume(installation)
      end.to raise_error(Captain::ToolCatalog::WorkflowError) { |error| expect(error.code).to eq('installation_expired') }

      expect(installation.reload).to be_expired
    end
  end
end
