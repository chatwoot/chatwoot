require 'rails_helper'

RSpec.describe Captain::ToolCatalog::StripeConnection do
  subject(:connection) { described_class.new(account: account) }

  let(:account) { create(:account) }
  let(:credential) { "rk_test_#{'a' * 24}" }
  let(:stripe_account) do
    {
      object: 'account',
      id: 'acct_example',
      livemode: false,
      business_profile: { name: 'Acme Billing' }
    }
  end

  before { allow(Chatwoot).to receive(:encryption_configured?).and_return(true) }

  it 'validates the account and every selected resource before storing one safe account hook' do
    requests = []
    allow(SafeFetch).to receive(:fetch) do |url, **options, &block|
      requests << { url: url, options: options }
      body = url.end_with?('/account') ? JSON.generate(stripe_account) : JSON.generate(object: 'list', data: [])
      block.call(SafeFetch::Result.new(tempfile: StringIO.new(body), filename: 'response', content_type: 'application/json'))
    end

    hook = connection.connect!(
      credential: credential,
      required_scopes: ['payment_intents:read', 'customers:read']
    )

    expect(requests.pluck(:url)).to eq(
      [
        'https://api.stripe.com/v1/account',
        'https://api.stripe.com/v1/customers?limit=1',
        'https://api.stripe.com/v1/payment_intents?limit=1'
      ]
    )
    expect(requests.pluck(:options)).to all(
      include(
        method: :get,
        headers: { 'Authorization' => "Bearer #{credential}" },
        sensitive_headers: ['Authorization'],
        max_bytes: 64.kilobytes,
        validate_content_type: false
      )
    )
    expect(hook).to have_attributes(
      account: account,
      app_id: 'stripe',
      hook_type: 'account',
      status: 'enabled',
      reference_id: 'acct_example',
      access_token: credential
    )
    expect(hook.settings).to include(
      'account_name' => 'Acme Billing',
      'external_id' => 'acct_example',
      'livemode' => false,
      'scopes' => ['customers:read', 'payment_intents:read']
    )
    expect(hook.settings.to_json).not_to include(credential)
  end

  it 'rejects unrestricted and malformed keys before making a request' do
    allow(SafeFetch).to receive(:fetch)

    error_matcher = raise_error(Captain::ToolCatalog::WorkflowError) do |error|
      expect(error.code).to eq('stripe_restricted_key_required')
    end
    expect do
      connection.connect!(credential: "sk_test_#{'a' * 24}", required_scopes: ['customers:read'])
    end.to error_matcher
    expect(SafeFetch).not_to have_received(:fetch)
    expect(account.hooks).to be_empty
  end

  it 'does not replace an existing connection when a selected resource check fails' do
    existing_hook = create(
      :integrations_hook,
      account: account,
      app_id: 'stripe',
      access_token: 'existing-secret',
      settings: { scopes: ['customers:read'] }
    )
    request_count = 0
    allow(SafeFetch).to receive(:fetch) do |_url, **_options, &block|
      request_count += 1
      raise SafeFetch::HttpError, '403 Forbidden' if request_count == 2

      body = JSON.generate(stripe_account)
      block.call(SafeFetch::Result.new(tempfile: StringIO.new(body), filename: 'response', content_type: 'application/json'))
    end

    expect do
      connection.connect!(credential: credential, required_scopes: ['invoices:read'])
    end.to raise_error(Captain::ToolCatalog::WorkflowError) { |error| expect(error.code).to eq('stripe_scope_missing') }

    expect(existing_hook.reload).to have_attributes(access_token: 'existing-secret', settings: { 'scopes' => ['customers:read'] })
  end

  it 'rejects a malformed Stripe account response without persisting the credential' do
    allow(SafeFetch).to receive(:fetch) do |_url, **_options, &block|
      body = JSON.generate(object: 'customer', id: 'cus_example')
      block.call(SafeFetch::Result.new(tempfile: StringIO.new(body), filename: 'response', content_type: 'application/json'))
    end

    expect do
      connection.connect!(credential: credential, required_scopes: ['customers:read'])
    end.to raise_error(Captain::ToolCatalog::WorkflowError) { |error| expect(error.code).to eq('stripe_invalid_response') }

    expect(account.hooks).to be_empty
  end

  it 'rejects a malformed selected-resource response without persisting the credential' do
    response_count = 0
    allow(SafeFetch).to receive(:fetch) do |_url, **_options, &block|
      response_count += 1
      body = response_count == 1 ? JSON.generate(stripe_account) : JSON.generate(object: 'account', id: 'acct_example')
      block.call(SafeFetch::Result.new(tempfile: StringIO.new(body), filename: 'response', content_type: 'application/json'))
    end

    expect do
      connection.connect!(credential: credential, required_scopes: ['customers:read'])
    end.to raise_error(Captain::ToolCatalog::WorkflowError) { |error| expect(error.code).to eq('stripe_invalid_response') }

    expect(account.hooks).to be_empty
  end
end
