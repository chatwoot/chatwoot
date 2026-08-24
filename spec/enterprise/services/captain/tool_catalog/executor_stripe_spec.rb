require 'rails_helper'

RSpec.describe Captain::ToolCatalog::Executor do
  let(:account) { create(:account) }
  let(:credential) { "rk_test_#{'a' * 24}" }
  let(:pack) do
    Captain::ToolCatalog::ProviderPackCompiler.new(
      pack_path: Rails.root.join('enterprise/config/captain/tool_catalog/providers/stripe')
    ).compile
  end
  let(:template) do
    pack.fetch('templates').find { |candidate| candidate.fetch('key') == 'get_last_five_payments' }
  end
  let(:hook) do
    create(
      :integrations_hook,
      account: account,
      app_id: 'stripe',
      access_token: credential,
      settings: { scopes: ['customers:read', 'payment_intents:read'] }
    )
  end
  let(:custom_tool) do
    attributes = Captain::ToolCatalog::SnapshotBuilder.new(
      pack: pack,
      entry: { template: template, configuration: {} },
      integration_hook: hook
    ).attributes
    account.captain_custom_tools.create!(attributes)
  end
  let(:executor) do
    described_class.new(
      custom_tool: custom_tool,
      state: { contact: { email: 'customer@example.com' } }
    )
  end
  let(:provider_responses) do
    [
      {
        object: 'list',
        data: [{ id: 'cus_example', email: 'customer@example.com' }]
      },
      {
        object: 'list',
        data: [
          {
            id: 'pi_example',
            amount: 2500,
            amount_received: 2500,
            currency: 'usd',
            status: 'succeeded',
            created: 1_767_225_600,
            client_secret: 'must-not-leave-the-executor',
            metadata: { internal: 'hidden' }
          }
        ]
      }
    ]
  end

  before do
    account.enable_features!('captain_tool_catalog')
    allow(Chatwoot).to receive(:encryption_configured?).and_return(true)
  end

  it 'uses the server-bound contact, runs the fixed recipe, and projects sensitive response fields away' do
    requests = []
    allow(SafeFetch).to receive(:fetch) do |url, **options, &block|
      requests << { url: url, headers: options.fetch(:headers) }
      body = JSON.generate(provider_responses.shift)
      block.call(SafeFetch::Result.new(tempfile: StringIO.new(body), filename: 'response', content_type: 'application/json'))
    end

    result = executor.perform({})

    expect(requests).to eq(
      [
        {
          url: 'https://api.stripe.com/v1/customers?email=customer%40example.com&limit=1',
          headers: { 'Authorization' => "Bearer #{credential}" }
        },
        {
          url: 'https://api.stripe.com/v1/payment_intents?customer=cus_example&limit=5',
          headers: { 'Authorization' => "Bearer #{credential}" }
        }
      ]
    )
    expect(result).to eq(
      'data' => [
        {
          'id' => 'pi_example',
          'amount' => 2500,
          'amount_received' => 2500,
          'currency' => 'usd',
          'status' => 'succeeded',
          'created' => 1_767_225_600
        }
      ]
    )
    expect(result.to_json).not_to include('client_secret', 'must-not-leave-the-executor', 'metadata')
  end

  it 'rejects model-supplied customer identity before making a provider request' do
    allow(SafeFetch).to receive(:fetch)

    expect { executor.perform(email: 'attacker@example.com') }
      .to raise_error(Captain::ToolCatalog::ExecutionError) { |error| expect(error.code).to eq('invalid_tool_input') }
    expect(SafeFetch).not_to have_received(:fetch)
  end
end
