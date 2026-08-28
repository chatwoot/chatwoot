require 'rails_helper'

RSpec.describe Captain::ToolCatalog::UpdateWorkflow do
  subject(:update_workflow) { described_class.new(account: account, initiated_by: admin, registry: registry) }

  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:pack) do
    compiled_pack = Captain::ToolCatalog::ProviderPackCompiler.new(
      pack_path: Rails.root.join('spec/fixtures/captain/tool_catalog/providers/example')
    ).compile.deep_dup
    template = compiled_pack.fetch('templates').sole
    compiled_pack['templates'] += [
      template.deep_merge('key' => 'list_recent_customers', 'stable_name' => 'example_list_recent_customers', 'name' => 'List recent customers'),
      template.deep_merge('key' => 'find_customer_by_phone', 'stable_name' => 'example_find_customer_by_phone', 'name' => 'Find customer by phone')
    ]
    compiled_pack
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

  it 'atomically adds, retains, and removes tools to match the selected set' do
    hook = create(:integrations_hook, account: account, app_id: 'example', settings: { scope: 'customers:read' })
    removed_tool = create(
      :captain_custom_tool,
      :catalog,
      account: account,
      provider_key: 'example',
      template_key: 'get_current_customer'
    )
    retained_tool = create(
      :captain_custom_tool,
      :catalog,
      account: account,
      provider_key: 'example',
      template_key: 'list_recent_customers',
      template_version: '0.9.0'
    )
    desired_templates = %w[list_recent_customers find_customer_by_phone].map do |template_key|
      { 'template_key' => template_key, 'template_version' => '1.0.0', 'configuration' => {} }
    end

    installation = update_workflow.perform(provider_key: 'example', templates: desired_templates)

    resulting_tools = account.captain_custom_tools.catalog.where(id: installation.resulting_tool_ids).order(:id)
    expect(installation).to be_completed
    expect(removed_tool.class.exists?(removed_tool.id)).to be(false)
    expect(resulting_tools.pluck(:template_key)).to contain_exactly('list_recent_customers', 'find_customer_by_phone')
    expect(retained_tool.reload).to have_attributes(template_version: '1.0.0', integration_hook_id: hook.id)
  end

  it 'does not remove tools before an added action receives its required scopes' do
    create(:integrations_hook, account: account, app_id: 'example', settings: {})
    existing_tool = create(
      :captain_custom_tool,
      :catalog,
      account: account,
      provider_key: 'example',
      template_key: 'get_current_customer'
    )
    desired_templates = [{
      'template_key' => 'find_customer_by_phone',
      'template_version' => '1.0.0',
      'configuration' => {}
    }]

    installation = update_workflow.perform(provider_key: 'example', templates: desired_templates)

    expect(installation).to be_awaiting_connection
    expect(existing_tool.class.exists?(existing_tool.id)).to be(true)
    expect(account.captain_custom_tools.catalog.where(provider_key: 'example')).to contain_exactly(existing_tool)
  end

  it 'allows every action to be removed without revoking the provider connection' do
    hook = create(:integrations_hook, account: account, app_id: 'example', settings: { scope: 'customers:read' })
    create(
      :captain_custom_tool,
      :catalog,
      account: account,
      provider_key: 'example',
      template_key: 'get_current_customer',
      integration_hook: hook
    )

    installation = update_workflow.perform(provider_key: 'example', templates: [])

    expect(installation).to be_completed
    expect(installation).to have_attributes(resulting_tool_ids: [], integration_hook_id: hook.id)
    expect(account.captain_custom_tools.catalog.where(provider_key: 'example')).to be_empty
    expect(hook.reload).to be_present
  end

  it 'uses the net tool change when replacing an action at account capacity' do
    hook = create(:integrations_hook, account: account, app_id: 'example', settings: { scope: 'customers:read' })
    create_list(:captain_custom_tool, Captain::CustomTool::MAX_PER_ACCOUNT - 1, account: account)
    create(
      :captain_custom_tool,
      :catalog,
      account: account,
      provider_key: 'example',
      template_key: 'get_current_customer',
      integration_hook: hook
    )
    desired_templates = [{
      'template_key' => 'list_recent_customers',
      'template_version' => '1.0.0',
      'configuration' => {}
    }]

    expect do
      update_workflow.perform(provider_key: 'example', templates: desired_templates)
    end.not_to(change { account.captain_custom_tools.count })

    expect(account.captain_custom_tools.catalog.where(provider_key: 'example').sole.template_key).to eq('list_recent_customers')
  end

  it 'does not mutate a matching tool from another account' do
    other_tool = create(:captain_custom_tool, :catalog, provider_key: 'example', template_key: 'get_current_customer')
    create(:integrations_hook, account: account, app_id: 'example', settings: { scope: 'customers:read' })

    installation = update_workflow.perform(provider_key: 'example', templates: templates)

    expect(installation).to be_completed
    expect(other_tool.reload.template_version).to eq('1.0.0')
    expect(account.captain_custom_tools.catalog.where(provider_key: 'example').sole.account).to eq(account)
  end
end
