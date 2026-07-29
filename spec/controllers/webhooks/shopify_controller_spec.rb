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

  it 'returns not found before HMAC verification when the installation switch is disabled' do
    hook
    allow(GlobalConfigService).to receive(:load)
      .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
      .and_return(false)

    expect do
      post '/webhooks/shopify', params: body, headers: headers
    end.not_to change(Integrations::Hook, :count)

    expect(response).to have_http_status(:not_found)
  end

  it 'keeps account data when the account feature is disabled' do
    hook
    account.disable_features!('shopify_integration')

    expect do
      post '/webhooks/shopify', params: body, headers: headers
    end.not_to change(Integrations::Hook, :count)

    expect(response).to have_http_status(:ok)
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
