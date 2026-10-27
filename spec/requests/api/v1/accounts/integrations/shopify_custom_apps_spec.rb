require 'rails_helper'

RSpec.describe 'Shopify custom app setup', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:headers) { admin.create_new_auth_token }
  let(:configuration_url) { "/api/v1/accounts/#{account.id}/integrations/shopify_custom_app" }
  let(:integration_url) { "/api/v1/accounts/#{account.id}/integrations/shopify" }
  let(:shop_domain) { 'test-store.myshopify.com' }
  let(:client_secret) { 'custom-app-secret' }
  let(:install_url) { 'https://admin.shopify.com/store/test-store/oauth/install_custom_app?client_id=test-client&signature=test-signature' }
  let(:configuration) { { shop_domain: shop_domain, client_id: 'test-client', client_secret: client_secret, install_url: install_url } }

  before do
    account.disable_features!('shopify_integration')
    account.enable_features!('shopify_custom_apps')
    InstallationConfig.where(name: 'ENABLE_SHOPIFY_INTEGRATION').first_or_initialize.update!(value: true)
  end

  it 'saves credentials privately, connects through Shopify, and removes the saved details on disconnect' do
    skip('encryption keys missing; see run_mfa_spec workflow') unless Chatwoot.encryption_configured?

    post configuration_url, params: configuration, headers: headers, as: :json
    saved_configuration = response.parsed_body.fetch('custom_app')
    expect(saved_configuration).to eq(
      'shop_domain' => shop_domain, 'client_id' => 'test-client', 'enabled' => false,
      'callback_url' => "#{ENV.fetch('FRONTEND_URL')}/shopify/accounts/#{account.id}/callback",
      'webhook_url' => "#{ENV.fetch('FRONTEND_URL')}/webhooks/shopify/accounts/#{account.id}"
    )

    patch configuration_url, params: { enabled: true }, headers: headers, as: :json
    post "#{integration_url}/auth", params: { shop_domain: shop_domain }, headers: headers, as: :json
    expect(response.parsed_body.fetch('redirect_url')).to eq(install_url)

    callback_path = URI(saved_configuration.fetch('callback_url')).path
    callback_params = { shop: shop_domain, timestamp: Time.current.to_i.to_s }
    callback_params[:hmac] = OpenSSL::HMAC.hexdigest('sha256', client_secret, URI.encode_www_form(callback_params.sort))
    get callback_path, params: callback_params
    state = Rack::Utils.parse_query(URI(response.location).query).fetch('state')

    stub_request(:post, "https://#{shop_domain}/admin/oauth/access_token")
      .to_return(status: 200, body: { access_token: 'store-access-token', scope: 'read_customers,read_orders,read_fulfillments' }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
    callback_params = { shop: shop_domain, code: 'authorization-code', state: state }
    callback_params[:hmac] = OpenSSL::HMAC.hexdigest('sha256', client_secret, URI.encode_www_form(callback_params.sort))
    get callback_path, params: callback_params
    expect(account.hooks.find_by!(app_id: 'shopify')).to have_attributes(access_token: 'store-access-token', status: 'enabled')

    delete configuration_url, headers: headers, as: :json
    expect(response).to have_http_status(:conflict)
    delete integration_url, headers: headers, as: :json
    expect(response).to have_http_status(:ok)
    expect([account.reload.shopify_custom_app, account.hooks.find_by(app_id: 'shopify')]).to eq([nil, nil])

    post configuration_url, params: configuration, headers: headers, as: :json
    expect(response.parsed_body.fetch('custom_app')).to eq(saved_configuration)
  end

  it 'shows custom setup and retrieves orders without public app credentials' do
    skip('encryption keys missing; see run_mfa_spec workflow') unless Chatwoot.encryption_configured?

    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('SHOPIFY_CLIENT_ID', nil).and_return(nil)
    allow(GlobalConfigService).to receive(:load).with('SHOPIFY_CLIENT_SECRET', nil).and_return(nil)
    get api_v1_account_integrations_apps_url(account), headers: headers, as: :json
    expect(response.parsed_body.fetch('payload').pluck('id')).to include('shopify')
    get api_v1_account_integrations_app_url(account_id: account.id, id: 'shopify'), headers: headers, as: :json
    expect(response).to have_http_status(:ok)

    post configuration_url, params: configuration, headers: headers, as: :json
    expect(response).to have_http_status(:ok)
    custom_app = account.reload.shopify_custom_app
    create(:integrations_hook, :shopify, account: account, reference_id: shop_domain,
                                         access_token: 'custom-token', settings: { custom_app_id: custom_app.id })
    contact = create(:contact, account: account, email: 'customer@example.com')
    stub_request(:get, %r{\Ahttps://test-store\.myshopify\.com/admin/api/[^/]+/customers/search\.json(?:\?|\z)})
      .with(headers: { 'X-Shopify-Access-Token' => 'custom-token' })
      .to_return(body: { customers: [{ id: 123 }] }.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, %r{\Ahttps://test-store\.myshopify\.com/admin/api/[^/]+/orders\.json(?:\?|\z)})
      .with(headers: { 'X-Shopify-Access-Token' => 'custom-token' })
      .to_return(body: { orders: [{ id: 456 }] }.to_json, headers: { 'Content-Type' => 'application/json' })

    get "#{integration_url}/orders", params: { contact_id: contact.id }, headers: headers, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('orders').first.fetch('id')).to eq(456)
  end

  context 'with a supported development store' do
    let(:shop_domain) { 'test-store.myshopify.io' }

    it 'lets administrators reset unfinished setup and enter the app details again' do
      skip('encryption keys missing; see run_mfa_spec workflow') unless Chatwoot.encryption_configured?

      post configuration_url, params: configuration, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      delete configuration_url, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      get configuration_url, headers: headers, as: :json
      expect(response.parsed_body).to eq('custom_app' => nil)
      post configuration_url, params: configuration, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  it 'does not let agents save app credentials' do
    agent = create(:user, account: account, role: :agent)
    post configuration_url, params: configuration, headers: agent.create_new_auth_token, as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(account.reload.shopify_custom_app).to be_nil
  end

  it 'hides custom setup when its feature flag is disabled' do
    account.disable_features!('shopify_custom_apps')
    post configuration_url, params: configuration, headers: headers, as: :json
    expect(response).to have_http_status(:not_found)
    expect(account.reload.shopify_custom_app).to be_nil
  end

  it 'keeps custom setup unavailable when the main Shopify integration is enabled' do
    account.enable_features!('shopify_integration')
    post configuration_url, params: configuration, headers: headers, as: :json
    expect(response).to have_http_status(:not_found)
    expect(account.reload.shopify_custom_app).to be_nil
  end
end
