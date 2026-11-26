require 'rails_helper'

RSpec.describe 'Shopify storefront widget API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:inbox) { create(:inbox, account: account) }
  let(:hook) { create(:integrations_hook, :shopify, account: account, settings: {}) }
  let(:client) { instance_double(ShopifyAPI::Clients::Graphql::Admin) }
  let(:url) { "/api/v1/accounts/#{account.id}/integrations/shopify_storefront_widget" }
  let(:installation_id) { 'gid://shopify/AppInstallation/123' }

  around do |example|
    with_modified_env(ENABLE_SHOPIFY_INTEGRATION: 'true') { example.run }
  end

  before do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    account.enable_features!('shopify_integration')
    hook
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('SHOPIFY_CLIENT_ID', nil).and_return('client-id')
    allow(Shopify::ApiContext).to receive(:setup!)
    allow(ShopifyAPI::Clients::Graphql::Admin).to receive(:new).and_return(client)
    allow(client).to receive(:query)
  end

  it 'loads the configured Website inbox and returns the theme editor link' do
    stub_installation(inbox.channel.website_token)

    get url, headers: admin.create_new_auth_token

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      'inbox_id' => inbox.id,
      'theme_editor_url' => 'https://test-store.myshopify.com/admin/themes/current/editor?context=apps&activateAppId=client-id%2Fchatwoot-chat'
    )
  end

  it 'returns empty settings when a previously configured inbox is outside this workspace' do
    stub_installation(create(:inbox).channel.website_token)

    get url, headers: admin.create_new_auth_token

    expect(response.parsed_body).to eq('inbox_id' => nil, 'theme_editor_url' => nil)
  end

  it 'saves only the public widget token on the Shopify installation' do
    stub_installation
    allow(client).to receive(:query).with(
      query: Shopify::StorefrontWidget::SET_METAFIELD_MUTATION,
      variables: { metafields: [{
        ownerId: installation_id, namespace: 'chatwoot', key: 'website_token',
        type: 'single_line_text_field', value: inbox.channel.website_token
      }] }
    ).and_return(shopify_response('metafieldsSet' => { 'metafields' => [{ 'id' => 'gid://shopify/Metafield/1' }], 'userErrors' => [] }))

    put url, params: { inbox_id: inbox.id }, headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['inbox_id']).to eq(inbox.id)
  end

  it 'rejects an inbox from another workspace before calling Shopify' do
    put url, params: { inbox_id: create(:inbox).id }, headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(client).not_to have_received(:query)
  end

  it 'rejects non-Website inboxes before calling Shopify' do
    put url, params: { inbox_id: create(:inbox, :with_email, account: account).id }, headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(client).not_to have_received(:query)
  end

  it 'rejects agents before calling Shopify' do
    agent = create(:user, account: account, role: :agent)

    put url, params: { inbox_id: inbox.id }, headers: agent.create_new_auth_token, as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(client).not_to have_received(:query)
  end

  it 'rejects storefront settings and saves on self-hosted installations' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
    headers = admin.create_new_auth_token

    get url, headers: headers
    expect(response).to have_http_status(:not_found)

    put url, params: { inbox_id: inbox.id }, headers: headers, as: :json
    expect(response).to have_http_status(:not_found)
    expect(client).not_to have_received(:query)
  end

  it 'does not show the storefront setup for custom-app installations' do
    hook.update!(settings: { 'custom_app_id' => 1 })

    get url, headers: admin.create_new_auth_token

    expect(response).to have_http_status(:not_found)
    expect(client).not_to have_received(:query)
  end

  it 'asks the administrator to reconnect when Shopify rejects the saved token' do
    shopify_http_response = ShopifyAPI::Clients::HttpResponse.new(code: 401, headers: {}, body: {})
    allow(client).to receive(:query).and_raise(ShopifyAPI::Errors::HttpResponseError.new(response: shopify_http_response))

    get url, headers: admin.create_new_auth_token

    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body).to eq('code' => 'shopify_reauthorization_required')
  end

  it 'reports Shopify write errors without claiming the inbox was saved' do
    stub_installation
    allow(client).to receive(:query).with(
      query: Shopify::StorefrontWidget::SET_METAFIELD_MUTATION, variables: anything
    ).and_return(shopify_response('metafieldsSet' => { 'userErrors' => [{ 'code' => 'INVALID_VALUE' }] }))

    put url, params: { inbox_id: inbox.id }, headers: admin.create_new_auth_token, as: :json

    expect(response).to have_http_status(:bad_gateway)
  end

  describe 'disconnecting the Shopify integration' do
    let(:widget_identifier) { { ownerId: installation_id, namespace: 'chatwoot', key: 'website_token' } }

    shared_examples 'Shopify storefront cleanup' do
      it 'clears the Shopify binding before deleting the connection and preserves the inbox' do
        stub_installation(inbox.channel.website_token)
        allow(client).to receive(:query).with(
          query: Shopify::StorefrontWidget::DELETE_METAFIELD_MUTATION,
          variables: { metafields: [widget_identifier] }
        ) do
          expect(Integrations::Hook.exists?(hook.id)).to be true
          shopify_response('metafieldsDelete' => { 'deletedMetafields' => [{ 'key' => 'website_token' }], 'userErrors' => [] })
        end

        delete disconnect_url, headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
        expect(Integrations::Hook.exists?(hook.id)).to be false
        expect(account.inboxes.exists?(inbox.id)).to be true
        expect(client).to have_received(:query).with(query: Shopify::StorefrontWidget::DELETE_METAFIELD_MUTATION, variables: anything)
      end

      it 'keeps the connection if Shopify rejects cleanup' do
        stub_installation(inbox.channel.website_token)
        allow(client).to receive(:query).with(
          query: Shopify::StorefrontWidget::DELETE_METAFIELD_MUTATION,
          variables: { metafields: [widget_identifier] }
        ).and_return(shopify_response('metafieldsDelete' => { 'deletedMetafields' => [], 'userErrors' => [{ 'message' => 'Access denied' }] }))

        delete disconnect_url, headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Integrations::Hook.exists?(hook.id)).to be true
      end
    end

    context 'when disconnecting through the Shopify endpoint' do
      let(:disconnect_url) { "/api/v1/accounts/#{account.id}/integrations/shopify" }

      it_behaves_like 'Shopify storefront cleanup'

      it 'disconnects a custom app without touching the public app storefront settings' do
        hook.update!(settings: { 'custom_app_id' => 1 })

        delete disconnect_url, headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
        expect(Integrations::Hook.exists?(hook.id)).to be false
        expect(client).not_to have_received(:query)
      end
    end

    context 'when disconnecting through the generic hook endpoint' do
      let(:disconnect_url) { api_v1_account_integrations_hook_url(account_id: account.id, id: hook.id) }

      it_behaves_like 'Shopify storefront cleanup'
    end
  end

  def stub_installation(token = nil)
    allow(client).to receive(:query).with(
      query: Shopify::StorefrontWidget::INSTALLATION_QUERY, variables: { namespace: 'chatwoot', key: 'website_token' }
    ).and_return(shopify_response('currentAppInstallation' => { 'id' => installation_id, 'metafield' => token && { 'value' => token } }))
  end

  def shopify_response(data)
    instance_double(ShopifyAPI::Clients::HttpResponse, body: { 'data' => data })
  end
end
