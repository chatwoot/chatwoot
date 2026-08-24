require 'rails_helper'

RSpec.describe Captain::ToolCatalog::Executor do
  subject(:executor) do
    described_class.new(
      custom_tool: custom_tool,
      state: { contact: { id: 17, email: 'customer@example.com' }, conversation: { id: 29, display_id: 104 } }
    )
  end

  let(:account) { create(:account) }
  let(:hook) do
    create(
      :integrations_hook,
      account: account,
      app_id: 'example',
      access_token: 'provider-secret',
      settings: { scope: 'customers:read' }
    )
  end
  let(:pack) do
    Captain::ToolCatalog::ProviderPackCompiler.new(
      pack_path: Rails.root.join('spec/fixtures/captain/tool_catalog/providers/example')
    ).compile
  end
  let(:entry) { { template: pack.fetch('templates').sole, configuration: {} } }
  let(:custom_tool) do
    account.captain_custom_tools.create!(
      Captain::ToolCatalog::SnapshotBuilder.new(pack: pack, entry: entry, integration_hook: hook).attributes
    )
  end
  let(:provider_response) do
    { id: 'customer_123', email: 'customer@example.com', client_secret: 'must-not-reach-model' }
  end

  before do
    account.enable_features!('captain_tool_catalog')
    allow(SafeFetch).to receive(:fetch) do |_url, **_options, &block|
      result = SafeFetch::Result.new(
        tempfile: StringIO.new(JSON.generate(provider_response)),
        filename: 'response',
        content_type: 'application/json'
      )
      block.call(result)
    end
  end

  it 'binds contact identity server-side, authenticates after validation, and projects the response' do
    expect(SafeFetch).to receive(:fetch) do |url, **options, &block|
      expect(url).to eq('https://api.example.com/customers?email=customer%40example.com')
      expect(options).to include(
        method: :get,
        headers: { 'Authorization' => 'Bearer provider-secret' },
        sensitive_headers: ['Authorization'],
        max_bytes: 256.kilobytes
      )
      block.call(
        SafeFetch::Result.new(
          tempfile: StringIO.new(JSON.generate(provider_response)),
          filename: 'response',
          content_type: 'application/json'
        )
      )
    end

    expect(executor.perform({})).to eq('id' => 'customer_123', 'email' => 'customer@example.com')
  end

  it 'emits sanitized execution instrumentation without inputs, outputs, or credentials' do
    event = nil
    subscription = ActiveSupport::Notifications.subscribe(described_class::EVENT_NAME) { |notification| event = notification }

    executor.perform({})

    expect(event.payload).to include(
      provider: 'example',
      template: 'get_current_customer',
      status: 'success',
      response_size: JSON.generate(provider_response).bytesize,
      error_category: nil
    )
    expect(event.payload[:duration_ms]).to be >= 0
    expect(event.payload.to_json).not_to include('customer@example.com', 'provider-secret', 'customer_123')
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription) if subscription
  end

  it 'rejects invalid model input before making a request' do
    custom_tool.update!(input_schema: {
                          'type' => 'object',
                          'additionalProperties' => false,
                          'required' => ['query'],
                          'properties' => { 'query' => { 'type' => 'string' } }
                        })

    expect { executor.perform({}) }
      .to raise_error(Captain::ToolCatalog::ExecutionError) { |error| expect(error.code).to eq('invalid_tool_input') }
    expect(SafeFetch).not_to have_received(:fetch)
  end

  it 'projects through local schema references before exposing nested provider data' do
    custom_tool.update!(output_schema: {
                          'type' => 'object',
                          'additionalProperties' => false,
                          'required' => ['customer'],
                          'properties' => { 'customer' => { '$ref' => '#/definitions/customer' } },
                          'definitions' => {
                            'customer' => {
                              'type' => 'object',
                              'additionalProperties' => false,
                              'required' => %w[id email],
                              'properties' => { 'id' => { 'type' => 'string' }, 'email' => { 'type' => 'string' } }
                            }
                          }
                        })
    response = {
      customer: {
        id: 'customer_123',
        email: 'customer@example.com',
        client_secret: 'must-not-reach-model'
      }
    }
    allow(SafeFetch).to receive(:fetch) do |_url, **_options, &block|
      result = SafeFetch::Result.new(tempfile: StringIO.new(JSON.generate(response)), filename: 'response', content_type: 'application/json')
      block.call(result)
    end

    expect(executor.perform({})).to eq(
      'customer' => { 'id' => 'customer_123', 'email' => 'customer@example.com' }
    )
  end

  it 'rejects a tampered operation origin before reading or attaching credentials' do
    custom_tool.definition['operations'].sole['request']['url'] = 'https://attacker.example/customers'

    expect { executor.perform({}) }
      .to raise_error(Captain::ToolCatalog::ExecutionError) { |error| expect(error.code).to eq('origin_not_allowed') }
    expect(SafeFetch).not_to have_received(:fetch)
  end

  it 'requires the installed tool connection to remain enabled and account scoped' do
    hook.update!(status: :disabled)

    expect { executor.perform({}) }
      .to raise_error(Captain::ToolCatalog::ExecutionError) do |error|
        expect(error).to have_attributes(category: 'disconnected', code: 'provider_reconnect_required')
      end
  end

  it 'rechecks provider scopes at invocation time' do
    hook.update!(settings: { scope: 'customers:write' })

    expect { executor.perform({}) }
      .to raise_error(Captain::ToolCatalog::ExecutionError) do |error|
        expect(error).to have_attributes(category: 'authorization', code: 'provider_scope_missing')
      end
  end

  it 'maps provider HTTP rate limits to a sanitized category' do
    allow(SafeFetch).to receive(:fetch).and_raise(SafeFetch::HttpError, '429 Too Many Requests')

    expect { executor.perform({}) }
      .to raise_error(Captain::ToolCatalog::ExecutionError) do |error|
        expect(error).to have_attributes(category: 'rate_limit', code: 'provider_rate_limited')
      end
  end

  it 'allows only fixed prior-step output paths to flow through a bounded recipe' do
    second_operation = custom_tool.definition.fetch('operations').sole.deep_dup
    second_operation['key'] = 'get_customer'
    second_operation['request']['url'] = 'https://api.example.com/customers/{customer_id}'
    second_operation['request']['parameters'] = [{ 'name' => 'customer_id', 'in' => 'path', 'required' => true }]
    custom_tool.definition['operations'] << second_operation
    custom_tool.definition['recipe'] << {
      'operation_key' => 'get_customer',
      'bindings' => { 'customer_id' => { 'source' => 'step_output', 'step' => 0, 'path' => 'id' } }
    }
    responses = [
      { id: 'customer_123', email: 'customer@example.com' },
      { id: 'customer_123', email: 'customer@example.com', internal_note: 'hidden' }
    ]
    requested_urls = []
    allow(SafeFetch).to receive(:fetch) do |url, **_options, &block|
      requested_urls << url
      body = JSON.generate(responses.shift)
      block.call(SafeFetch::Result.new(tempfile: StringIO.new(body), filename: 'response', content_type: 'application/json'))
    end

    expect(executor.perform({})).to eq('id' => 'customer_123', 'email' => 'customer@example.com')
    expect(requested_urls.second).to eq('https://api.example.com/customers/customer_123')
  end
end
