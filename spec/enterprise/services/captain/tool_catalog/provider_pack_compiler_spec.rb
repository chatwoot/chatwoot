require 'rails_helper'

RSpec.describe Captain::ToolCatalog::ProviderPackCompiler do
  subject(:compiled_pack) { described_class.new(pack_path: pack_path).compile }

  let(:pack_path) { Rails.root.join('spec/fixtures/captain/tool_catalog/providers/example') }

  it 'compiles REST and GraphQL operations into an immutable runtime definition' do
    expect(compiled_pack).to include(
      'provider' => include('key' => 'example', 'api_version' => 'v1'),
      'allowed_origins' => ['https://api.example.com'],
      'digest' => match(/\Asha256:[a-f0-9]{64}\z/)
    )
    expect(compiled_pack['operations'].pluck('source')).to contain_exactly('openapi', 'graphql')
    expect(compiled_pack['operations'].find { |operation| operation['source'] == 'graphql' }['definition'])
      .to include('query ListCustomersForSetup')
    expect(compiled_pack).to be_frozen
    expect(compiled_pack['templates']).to be_frozen
  end

  it 'derives stable model metadata from the recipe operations' do
    template = compiled_pack.fetch('templates').sole

    expect(template).to include(
      'stable_name' => 'example_get_current_customer',
      'effective_scopes' => ['customers:read'],
      'risk_class' => 'read',
      'model_visible' => true,
      'configuration_schema' => include('type' => 'object')
    )
  end

  it 'produces the same digest for the same Provider Pack' do
    next_compilation = described_class.new(pack_path: pack_path).compile

    expect(next_compilation).to eq(compiled_pack)
  end

  it 'rejects duplicate operation keys before compiling sources' do
    manifest = Captain::ToolCatalog::ProviderPackLoader.new(pack_path: pack_path).load.deep_dup
    manifest['operations'] << manifest['operations'].first.deep_dup
    loader = instance_double(Captain::ToolCatalog::ProviderPackLoader, load: manifest)
    allow(Captain::ToolCatalog::ProviderPackLoader).to receive(:new).and_return(loader)

    expect { compiled_pack }
      .to raise_error(Captain::ToolCatalog::ProviderPackError, 'Duplicate operation keys: find_customer')
  end

  it 'rejects origins containing a path' do
    manifest = Captain::ToolCatalog::ProviderPackLoader.new(pack_path: pack_path).load.deep_dup
    manifest['allowed_origins'] = ['https://api.example.com/v1']
    loader = instance_double(Captain::ToolCatalog::ProviderPackLoader, load: manifest)
    allow(Captain::ToolCatalog::ProviderPackLoader).to receive(:new).and_return(loader)

    expect { compiled_pack }
      .to raise_error(Captain::ToolCatalog::ProviderPackError, /must be an exact HTTPS origin/)
  end

  it 'keeps setup operations out of runtime recipes' do
    manifest = Captain::ToolCatalog::ProviderPackLoader.new(pack_path: pack_path).load.deep_dup
    manifest.dig('templates', 0, 'recipe', 0)['operation_key'] = 'list_customers_for_setup'
    loader = instance_double(Captain::ToolCatalog::ProviderPackLoader, load: manifest)
    allow(Captain::ToolCatalog::ProviderPackLoader).to receive(:new).and_return(loader)

    expect { compiled_pack }
      .to raise_error(Captain::ToolCatalog::ProviderPackError, /Setup operation cannot appear in a runtime recipe/)
  end

  it 'keeps approval-required templates out of the model tool list' do
    manifest = Captain::ToolCatalog::ProviderPackLoader.new(pack_path: pack_path).load.deep_dup
    approval_operation = manifest['operations'].first.deep_dup.merge(
      'key' => 'refund_customer',
      'risk_class' => 'approval_required'
    )
    approval_template = manifest['templates'].first.deep_dup.merge(
      'key' => 'refund_customer',
      'availability' => 'approval_required',
      'recipe' => [{ 'operation_key' => 'refund_customer', 'bindings' => {} }]
    )
    manifest['operations'] << approval_operation
    manifest['templates'] << approval_template
    loader = instance_double(Captain::ToolCatalog::ProviderPackLoader, load: manifest)
    allow(Captain::ToolCatalog::ProviderPackLoader).to receive(:new).and_return(loader)

    template = compiled_pack['templates'].find { |entry| entry['key'] == 'refund_customer' }

    expect(template).to include('risk_class' => 'approval_required', 'model_visible' => false)
  end

  it 'rejects credentials embedded in literal bindings' do
    manifest = Captain::ToolCatalog::ProviderPackLoader.new(pack_path: pack_path).load.deep_dup
    manifest.dig('templates', 0, 'recipe', 0, 'bindings')['credential'] = {
      'source' => 'literal',
      'value' => 'sk_live_1234567890123456'
    }
    loader = instance_double(Captain::ToolCatalog::ProviderPackLoader, load: manifest)
    allow(Captain::ToolCatalog::ProviderPackLoader).to receive(:new).and_return(loader)

    expect { compiled_pack }
      .to raise_error(Captain::ToolCatalog::ProviderPackError, /contains a secret literal/)
  end
end
