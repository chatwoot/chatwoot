require 'rails_helper'

RSpec.describe Captain::ToolCatalog::TemplateSelection do
  subject(:resolver) { described_class.new(registry: registry) }

  let(:pack) do
    Captain::ToolCatalog::ProviderPackCompiler.new(
      pack_path: Rails.root.join('spec/fixtures/captain/tool_catalog/providers/example')
    ).compile
  end
  let(:registry) { instance_double(Captain::ToolCatalog::ProviderPackRegistry, find: pack) }
  let(:templates) do
    [{ 'template_key' => 'get_current_customer', 'template_version' => '1.0.0', 'configuration' => {} }]
  end

  it 'resolves exact available versions and effective scopes' do
    selection = resolver.resolve(provider_key: 'example', templates: templates)

    expect(selection.serialized).to eq(templates)
    expect(selection.required_scopes).to eq(['customers:read'])
  end

  it 'rejects duplicate template selections' do
    expect do
      resolver.resolve(provider_key: 'example', templates: templates * 2)
    end.to raise_error(Captain::ToolCatalog::WorkflowError) { |error| expect(error.code).to eq('duplicate_templates') }
  end

  it 'rejects a stale expected version' do
    templates.first['template_version'] = '0.9.0'

    expect do
      resolver.resolve(provider_key: 'example', templates: templates)
    end.to raise_error(Captain::ToolCatalog::WorkflowError) { |error| expect(error.code).to eq('template_version_changed') }
  end

  it 'rejects configuration outside the compiled JSON Schema' do
    templates.first['configuration'] = { 'unexpected' => true }

    expect do
      resolver.resolve(provider_key: 'example', templates: templates)
    end.to raise_error(Captain::ToolCatalog::WorkflowError) { |error| expect(error.code).to eq('invalid_configuration') }
  end

  it 'rejects approval-required templates even when they remain visible in the catalog' do
    mutable_pack = pack.deep_dup
    mutable_pack.dig('templates', 0)['availability'] = 'approval_required'
    mutable_pack.dig('templates', 0)['model_visible'] = false
    allow(registry).to receive(:find).and_return(mutable_pack)

    expect do
      resolver.resolve(provider_key: 'example', templates: templates)
    end.to raise_error(Captain::ToolCatalog::WorkflowError) { |error| expect(error.code).to eq('template_unavailable') }
  end

  it 'rejects credential-like values even in otherwise valid non-secret configuration fields' do
    mutable_pack = pack.deep_dup
    mutable_pack.dig('templates', 0, 'configuration_schema', 'properties')['note'] = { 'type' => 'string' }
    allow(registry).to receive(:find).and_return(mutable_pack)
    templates.first['configuration'] = { 'note' => "sk_test_#{'a' * 20}" }

    expect do
      resolver.resolve(provider_key: 'example', templates: templates)
    end.to raise_error(Captain::ToolCatalog::WorkflowError) { |error| expect(error.code).to eq('secret_configuration_rejected') }
  end
end
