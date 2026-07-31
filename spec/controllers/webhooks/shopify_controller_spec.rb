require 'rails_helper'

RSpec.describe Webhooks::ShopifyController, type: :request do
  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, :shopify, account: account, reference_id: shop_domain) }
  let(:shop_domain) { 'feature-gated-shop.myshopify.com' }
  let(:client_secret) { 'shopify-client-secret' }
  let(:payload) { { shop_domain: shop_domain } }
  let(:body) { payload.to_json }
  let(:headers) do
    {
      'CONTENT_TYPE' => 'application/json',
      'X-Shopify-Topic' => 'shop/redact',
      'X-Shopify-Hmac-SHA256' => Base64.strict_encode64(OpenSSL::HMAC.digest('SHA256', client_secret, body))
    }
  end

  before do
    account.enable_features!('shopify_integration')
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load)
      .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
      .and_return(true)
    allow(GlobalConfigService).to receive(:load)
      .with('SHOPIFY_CLIENT_SECRET', nil)
      .and_return(client_secret)
  end

  it 'processes the webhook when both feature gates are enabled' do
    hook

    expect do
      post '/webhooks/shopify', params: body, headers: headers
    end.to change(Integrations::Hook, :count).by(-1)

    expect(response).to have_http_status(:ok)
  end

  it 'processes redaction when the installation switch is disabled' do
    hook
    allow(GlobalConfigService).to receive(:load)
      .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
      .and_return(false)

    expect do
      post '/webhooks/shopify', params: body, headers: headers
    end.to change(Integrations::Hook, :count).by(-1)

    expect(response).to have_http_status(:ok)
  end

  it 'authenticates and acknowledges every compliance topic when the installation switch is disabled' do
    allow(GlobalConfigService).to receive(:load)
      .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
      .and_return(false)

    Webhooks::ShopifyController::COMPLIANCE_TOPICS.each do |topic|
      headers['X-Shopify-Topic'] = topic

      post '/webhooks/shopify', params: body, headers: headers

      expect(response).to have_http_status(:ok)
    end
  end

  it 'processes redaction when the account feature is disabled' do
    hook
    account.disable_features!('shopify_integration')

    expect do
      post '/webhooks/shopify', params: body, headers: headers
    end.to change(Integrations::Hook, :count).by(-1)

    expect(response).to have_http_status(:ok)
  end

  it 'raises a retryable failure when a matching hook appears during cleanup' do
    hook
    inserted_hook = nil
    hooks = Integrations::Hook.where(app_id: 'shopify', reference_id: shop_domain)

    allow(Integrations::Hook).to receive(:where)
      .with(app_id: 'shopify', reference_id: shop_domain)
      .and_return(hooks)
    allow(hooks).to receive(:find_each) do |&block|
      block.call(hook)
      inserted_hook ||= create(:integrations_hook, :shopify, account: create(:account), reference_id: shop_domain)
    end

    post '/webhooks/shopify', params: body, headers: headers

    expect(response).to have_http_status(:internal_server_error)
    expect(inserted_hook).to be_persisted
  end

  it 'does not process normal events when the installation switch is disabled' do
    headers['X-Shopify-Topic'] = 'app/uninstalled'
    allow(GlobalConfigService).to receive(:load)
      .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
      .and_return(false)

    post '/webhooks/shopify', params: body, headers: headers

    expect(response).to have_http_status(:not_found)
  end

  it 'rejects an invalid HMAC without changing account data' do
    hook
    headers['X-Shopify-Hmac-SHA256'] = 'invalid'

    expect do
      post '/webhooks/shopify', params: body, headers: headers
    end.not_to change(Integrations::Hook, :count)

    expect(response).to have_http_status(:unauthorized)
  end
end
