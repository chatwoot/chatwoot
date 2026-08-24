require 'rails_helper'

RSpec.describe Captain::ToolCatalog::ProviderPackSourceLoader do
  subject(:source_loader) { described_class.new(pack_path: pack_path) }

  let(:pack_path) { Rails.root.join('spec/fixtures/captain/tool_catalog/providers/example') }

  it 'extracts a reviewed OpenAPI operation through a local JSON pointer' do
    operation = source_loader.load_operation(
      'source' => 'openapi',
      'reference' => 'openapi.yml#/paths/~1customers/get'
    )

    expect(operation.definition['operationId']).to eq('findCustomer')
    expect(operation.request).to include(
      'method' => 'GET',
      'url' => 'https://api.example.com/customers',
      'encoding' => 'query'
    )
  end

  it 'loads a fixed GraphQL document' do
    operation = source_loader.load_operation(
      'source' => 'graphql',
      'reference' => 'operations/list_customers.graphql',
      'endpoint' => 'https://api.example.com/graphql'
    )

    expect(operation.definition).to include('query ListCustomersForSetup')
    expect(operation.request).to include('method' => 'POST', 'encoding' => 'graphql')
  end

  it 'rejects references that escape the Provider Pack directory' do
    expect { source_loader.load_fixture('../../../../../../config/database.yml') }
      .to raise_error(Captain::ToolCatalog::ProviderPackError, /escapes its directory/)
  end

  it 'rejects missing referenced files' do
    expect { source_loader.load_schema('schemas/missing.json') }
      .to raise_error(Captain::ToolCatalog::ProviderPackError, /reference not found/)
  end
end
