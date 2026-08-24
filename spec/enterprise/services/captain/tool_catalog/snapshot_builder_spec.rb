require 'rails_helper'

RSpec.describe Captain::ToolCatalog::SnapshotBuilder do
  let(:pack) do
    Captain::ToolCatalog::ProviderPackCompiler.new(
      pack_path: Rails.root.join('spec/fixtures/captain/tool_catalog/providers/example')
    ).compile
  end
  let(:entry) { { template: pack.fetch('templates').sole, configuration: {} } }
  let(:hook) { create(:integrations_hook, app_id: 'example', access_token: 'provider-secret') }

  it 'builds a secret-free snapshot containing only recipe operations' do
    attributes = described_class.new(pack: pack, entry: entry, integration_hook: hook).attributes

    expect(attributes).to include(
      source_kind: 'catalog',
      provider_key: 'example',
      template_key: 'get_current_customer',
      template_version: '1.0.0',
      integration_hook_id: hook.id,
      endpoint_url: nil,
      auth_config: {}
    )
    expect(attributes.dig(:definition, 'operations').pluck('key')).to eq(['find_customer'])
    expect(attributes[:definition_digest]).to match(/\Asha256:[a-f0-9]{64}\z/)
    expect(attributes.to_json).not_to include('provider-secret', 'list_customers_for_setup')
  end

  it 'produces the same digest for the same compiled definition' do
    first = described_class.new(pack: pack, entry: entry, integration_hook: hook).attributes
    second = described_class.new(pack: pack, entry: entry, integration_hook: hook).attributes

    expect(first[:definition_digest]).to eq(second[:definition_digest])
  end
end
