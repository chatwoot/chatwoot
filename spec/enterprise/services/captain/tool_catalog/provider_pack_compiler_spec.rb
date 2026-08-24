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
    expect(compiled_pack['operations'].find { |operation| operation['source'] == 'openapi' }['request']).to include(
      'method' => 'GET',
      'url' => 'https://api.example.com/customers',
      'encoding' => 'query'
    )
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

  it 'rejects operation endpoints outside the provider allowlist' do
    manifest = Captain::ToolCatalog::ProviderPackLoader.new(pack_path: pack_path).load.deep_dup
    manifest['operations'].find { |operation| operation['source'] == 'graphql' }['endpoint'] = 'https://attacker.example/graphql'
    loader = instance_double(Captain::ToolCatalog::ProviderPackLoader, load: manifest)
    allow(Captain::ToolCatalog::ProviderPackLoader).to receive(:new).and_return(loader)

    expect { compiled_pack }
      .to raise_error(Captain::ToolCatalog::ProviderPackError, /outside the provider allowlist/)
  end

  it 'compiles Shopify GraphQL operations against the allowlisted tenant endpoint strategy' do
    manifest = Captain::ToolCatalog::ProviderPackLoader.new(pack_path: pack_path).load.deep_dup
    manifest['key'] = 'shopify'
    manifest['allowed_origins'] << 'https://*.myshopify.com'
    graphql_operation = manifest['operations'].find { |operation| operation['source'] == 'graphql' }
    graphql_operation.delete('endpoint')
    graphql_operation['endpoint_strategy'] = 'shopify_admin_graphql'
    loader = instance_double(Captain::ToolCatalog::ProviderPackLoader, load: manifest)
    allow(Captain::ToolCatalog::ProviderPackLoader).to receive(:new).and_return(loader)

    request = compiled_pack.fetch('operations').find { |operation| operation['source'] == 'graphql' }.fetch('request')

    expect(request).to include('endpoint_strategy' => 'shopify_admin_graphql')
    expect(request).not_to have_key('url')
  end

  it 'rejects the Shopify endpoint strategy for another provider' do
    manifest = Captain::ToolCatalog::ProviderPackLoader.new(pack_path: pack_path).load.deep_dup
    manifest['allowed_origins'] << 'https://*.myshopify.com'
    graphql_operation = manifest['operations'].find { |operation| operation['source'] == 'graphql' }
    graphql_operation.delete('endpoint')
    graphql_operation['endpoint_strategy'] = 'shopify_admin_graphql'
    loader = instance_double(Captain::ToolCatalog::ProviderPackLoader, load: manifest)
    allow(Captain::ToolCatalog::ProviderPackLoader).to receive(:new).and_return(loader)

    expect { compiled_pack }
      .to raise_error(Captain::ToolCatalog::ProviderPackError, /endpoint strategy is not allowed/)
  end

  it 'rejects Shopify-only bindings for another provider' do
    manifest = Captain::ToolCatalog::ProviderPackLoader.new(pack_path: pack_path).load.deep_dup
    manifest.dig('templates', 0, 'recipe', 0, 'bindings', 'email').replace('source' => 'shopify_contact_query')
    loader = instance_double(Captain::ToolCatalog::ProviderPackLoader, load: manifest)
    allow(Captain::ToolCatalog::ProviderPackLoader).to receive(:new).and_return(loader)

    expect { compiled_pack }
      .to raise_error(Captain::ToolCatalog::ProviderPackError, /only available to Shopify Provider Packs/)
  end

  it 'rejects Linear-only bindings for another provider' do
    manifest = Captain::ToolCatalog::ProviderPackLoader.new(pack_path: pack_path).load.deep_dup
    manifest.dig('templates', 0, 'recipe', 0, 'bindings', 'email').replace('source' => 'linear_conversation_url')
    loader = instance_double(Captain::ToolCatalog::ProviderPackLoader, load: manifest)
    allow(Captain::ToolCatalog::ProviderPackLoader).to receive(:new).and_return(loader)

    expect { compiled_pack }
      .to raise_error(Captain::ToolCatalog::ProviderPackError, /only available to Linear Provider Packs/)
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

  it 'requires installation configuration schemas to be closed objects' do
    source_loader = Captain::ToolCatalog::ProviderPackSourceLoader.new(pack_path: pack_path)
    allow(Captain::ToolCatalog::ProviderPackSourceLoader).to receive(:new).and_return(source_loader)
    allow(source_loader).to receive(:load_schema).and_call_original
    allow(source_loader).to receive(:load_schema).with('schemas/empty_configuration.json').and_return({})

    expect { compiled_pack }
      .to raise_error(Captain::ToolCatalog::ProviderPackError, /Configuration schema must be a closed object/)
  end

  it 'rejects credential fields in installation configuration schemas' do
    configuration_schema = JSON.parse(
      Rails.root.join('spec/fixtures/captain/tool_catalog/providers/example/schemas/empty_configuration.json').read
    )
    configuration_schema['properties']['api_key'] = { 'type' => 'string' }
    source_loader = Captain::ToolCatalog::ProviderPackSourceLoader.new(pack_path: pack_path)
    allow(Captain::ToolCatalog::ProviderPackSourceLoader).to receive(:new).and_return(source_loader)
    allow(source_loader).to receive(:load_schema).and_call_original
    allow(source_loader).to receive(:load_schema).with('schemas/empty_configuration.json').and_return(configuration_schema)

    expect { compiled_pack }
      .to raise_error(Captain::ToolCatalog::ProviderPackError, /Configuration schema contains credential fields: api_key/)
  end

  it 'requires bounded arrays in model and projected output schemas' do
    output_schema = {
      'type' => 'object',
      'additionalProperties' => false,
      'properties' => {
        'customers' => { 'type' => 'array', 'items' => { 'type' => 'string' } }
      }
    }
    source_loader = Captain::ToolCatalog::ProviderPackSourceLoader.new(pack_path: pack_path)
    allow(Captain::ToolCatalog::ProviderPackSourceLoader).to receive(:new).and_return(source_loader)
    allow(source_loader).to receive(:load_schema).and_call_original
    allow(source_loader).to receive(:load_schema).with('schemas/get_current_customer_output.json').and_return(output_schema)

    expect { compiled_pack }
      .to raise_error(Captain::ToolCatalog::ProviderPackError, /arrays must set maxItems between 1 and 10/)
  end

  it 'rejects external JSON Schema references' do
    input_schema = {
      'type' => 'object',
      'additionalProperties' => false,
      'properties' => { 'query' => { '$ref' => 'https://attacker.example/schema.json' } }
    }
    source_loader = Captain::ToolCatalog::ProviderPackSourceLoader.new(pack_path: pack_path)
    allow(Captain::ToolCatalog::ProviderPackSourceLoader).to receive(:new).and_return(source_loader)
    allow(source_loader).to receive(:load_schema).and_call_original
    allow(source_loader).to receive(:load_schema).with('schemas/get_current_customer_input.json').and_return(input_schema)

    expect { compiled_pack }
      .to raise_error(Captain::ToolCatalog::ProviderPackError, /Schema contains an external reference/)
  end

  it 'rejects credential fields in projected output schemas' do
    output_schema = {
      'type' => 'object',
      'additionalProperties' => false,
      'properties' => { 'client_secret' => { 'type' => 'string' } }
    }
    source_loader = Captain::ToolCatalog::ProviderPackSourceLoader.new(pack_path: pack_path)
    allow(Captain::ToolCatalog::ProviderPackSourceLoader).to receive(:new).and_return(source_loader)
    allow(source_loader).to receive(:load_schema).and_call_original
    allow(source_loader).to receive(:load_schema).with('schemas/get_current_customer_output.json').and_return(output_schema)

    expect { compiled_pack }
      .to raise_error(Captain::ToolCatalog::ProviderPackError, /Output schema contains credential fields/)
  end
end
