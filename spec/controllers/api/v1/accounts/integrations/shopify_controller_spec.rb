require 'rails_helper'

# Stub class for ShopifyAPI response
class ShopifyAPIResponse
  attr_reader :body

  def initialize(body)
    @body = body
  end
end

RSpec.describe 'Shopify Integration API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:unauthorized_agent) { create(:user, account: account, role: :agent) }
  let(:contact) { create(:contact, account: account, email: 'test@example.com', phone_number: '+1234567890') }

  before do
    account.enable_features!('shopify_integration')
    InstallationConfig.where(name: 'ENABLE_SHOPIFY_INTEGRATION').first_or_initialize.update!(value: true)
    allow(Shopify::ApiContext).to receive(:setup!)
  end

  describe 'GET /api/v1/accounts/:account_id/integrations/shopify/orders' do
    let!(:hook) { create(:integrations_hook, :shopify, account: account) }
    let(:graphql_url) { "https://#{hook.reference_id}/admin/api/#{Shopify::ApiContext::API_VERSION}/graphql.json" }
    let(:orders_path) { "/api/v1/accounts/#{account.id}/integrations/shopify/orders" }

    context 'when it is an authenticated user' do
      let(:customer_query) { 'email:"test@example.com" OR phone:"+1234567890"' }
      let(:order_node) do
        {
          legacyResourceId: '456',
          email: 'test@example.com',
          createdAt: '2026-11-01T12:00:00Z',
          displayFulfillmentStatus: 'PARTIALLY_FULFILLED',
          displayFinancialStatus: 'PARTIALLY_PAID',
          totalPriceSet: { shopMoney: { amount: '100.00', currencyCode: 'CAD' } }
        }
      end
      let(:customers) { [{ orders: { nodes: [order_node] } }] }
      let(:graphql_response) { { data: { customers: { nodes: customers } } } }
      let(:provider_status) { 200 }

      before do
        allow(Shopify::ApiContext).to receive(:setup!).and_call_original
        allow(GlobalConfigService).to receive(:load).and_call_original
        allow(GlobalConfigService).to receive(:load).with('SHOPIFY_CLIENT_ID', nil).and_return('public-client')
        allow(GlobalConfigService).to receive(:load).with('SHOPIFY_CLIENT_SECRET', nil).and_return('public-secret')
        stub_request(:post, graphql_url)
          .with(headers: { 'X-Shopify-Access-Token' => hook.access_token },
                body: { query: Shopify::OrderLookup::QUERY, variables: { customerQuery: customer_query, orderLimit: 50 } })
          .to_return(status: provider_status, body: graphql_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns the existing sidebar response fields' do
        get orders_path, params: { contact_id: contact.id }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.fetch('orders').sole).to eq(
          'id' => 456,
          'email' => 'test@example.com',
          'created_at' => '2026-11-01T12:00:00Z',
          'total_price' => '100.00',
          'currency' => 'CAD',
          'fulfillment_status' => 'partial',
          'financial_status' => 'partially_paid',
          'admin_url' => "https://#{hook.reference_id}/admin/orders/456"
        )
      end

      it 'returns an error when contact has no email or phone' do
        contact_without_info = create(:contact, account: account)

        get orders_path, params: { contact_id: contact_without_info.id }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Contact information missing')
        expect(WebMock).not_to have_requested(:post, graphql_url)
      end

      it 'rejects a disabled retained hook before calling Shopify' do
        hook.update!(status: :disabled, access_token: nil)

        get orders_path, params: { contact_id: contact.id }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
        expect(WebMock).not_to have_requested(:post, graphql_url)
      end

      context 'with only a phone number' do
        let(:contact) { create(:contact, account: account, email: nil, phone_number: '+1234567890') }
        let(:customer_query) { 'phone:"+1234567890"' }

        it 'finds the customer by phone' do
          get orders_path, params: { contact_id: contact.id }, headers: agent.create_new_auth_token, as: :json

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body.fetch('orders').pluck('id')).to eq([456])
        end
      end

      context 'when no customer matches' do
        let(:customers) { [] }

        it 'returns no orders' do
          get orders_path, params: { contact_id: contact.id }, headers: agent.create_new_auth_token, as: :json

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body.fetch('orders')).to eq([])
        end
      end

      context 'when the matched customer has no orders' do
        let(:customers) { [{ orders: { nodes: [] } }] }

        it 'returns no orders' do
          get orders_path, params: { contact_id: contact.id }, headers: agent.create_new_auth_token, as: :json

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body.fetch('orders')).to eq([])
        end
      end

      context 'when Shopify returns GraphQL errors with HTTP 200' do
        let(:graphql_response) { { errors: [{ message: 'Access denied for orders field' }], data: nil } }

        it 'returns an error for the sidebar' do
          get orders_path, params: { contact_id: contact.id }, headers: agent.create_new_auth_token, as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body.fetch('error')).to eq('Shopify could not load orders')
        end
      end

      context 'when Shopify rejects the access token' do
        let(:provider_status) { 401 }
        let(:graphql_response) { { errors: 'Invalid API key or access token' } }

        it 'returns an error for the sidebar' do
          get orders_path, params: { contact_id: contact.id }, headers: agent.create_new_auth_token, as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body.fetch('error')).to include('Invalid API key or access token')
        end
      end
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/integrations/shopify/orders",
            params: { contact_id: contact.id },
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when Shopify is disabled' do
      it 'returns not found when the installation switch is disabled' do
        InstallationConfig.where(name: 'ENABLE_SHOPIFY_INTEGRATION').first_or_initialize.update!(value: false)

        get "/api/v1/accounts/#{account.id}/integrations/shopify/orders",
            params: { contact_id: contact.id },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns not found when the account feature is disabled' do
        account.disable_features!('shopify_integration')

        get "/api/v1/accounts/#{account.id}/integrations/shopify/orders",
            params: { contact_id: contact.id },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/integrations/shopify/complete_install' do
    let(:account) { create(:account, internal_attributes: { billing_provider: 'shopify', signup_source: 'shopify' }) }
    let(:admin) { create(:user, account: account, role: :administrator) }
    let(:pending_install_token) { SecureRandom.hex(16) }
    let(:pending_installation) do
      instance_double(
        Shopify::PendingInstallation,
        data: {
          'access_token' => 'shopify-access-token',
          'shop' => 'my-store.myshopify.com',
          'scope' => 'read_customers,read_orders',
          'connected_at' => Time.current.utc.iso8601(6)
        }
      )
    end

    it 'keeps the legacy completion endpoint available during rolling deployments' do
      allow(Shopify::PendingInstallation).to receive(:claim)
        .with(token: pending_install_token)
        .and_return(pending_installation)
      allow(pending_installation).to receive(:with_current_installation).and_yield
      allow(pending_installation).to receive(:consume!)

      expect do
        post "/api/v1/accounts/#{account.id}/integrations/shopify/complete_install",
             params: { pending_install_token: pending_install_token },
             headers: admin.create_new_auth_token,
             as: :json
      end.to change(Integrations::Hook, :count).by(1)

      hook = account.hooks.find_by!(app_id: 'shopify')
      expect(hook).to have_attributes(
        access_token: 'shopify-access-token',
        reference_id: 'my-store.myshopify.com',
        status: 'enabled'
      )
      expect(hook.settings).to include(
        'scope' => 'read_customers,read_orders',
        'connected_at' => match(/\.\d{6}Z\z/),
        'installation_id' => be_present
      )
      expect(pending_installation).to have_received(:consume!)
      expect(response).to have_http_status(:ok)
    end

    it 'rejects agents before claiming the pending install' do
      expect(Shopify::PendingInstallation).not_to receive(:claim)

      post "/api/v1/accounts/#{account.id}/integrations/shopify/complete_install",
           params: { pending_install_token: pending_install_token },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'releases the claim and removes the hook when consumption fails' do
      allow(Shopify::PendingInstallation).to receive(:claim)
        .with(token: pending_install_token)
        .and_return(pending_installation)
      allow(pending_installation).to receive(:with_current_installation).and_yield
      allow(pending_installation).to receive(:consume!)
        .and_raise(Shopify::PendingInstallation::AlreadyClaimed, 'Install token claim has expired')
      allow(pending_installation).to receive(:release!)

      expect do
        post "/api/v1/accounts/#{account.id}/integrations/shopify/complete_install",
             params: { pending_install_token: pending_install_token },
             headers: admin.create_new_auth_token,
             as: :json
      end.not_to change(Integrations::Hook, :count)

      expect(pending_installation).to have_received(:release!)
      expect(response).to have_http_status(:conflict)
    end

    it 'returns a duplicate-store error and releases the retained claim' do
      allow(pending_installation).to receive(:with_current_installation).and_yield
      other_account = create(:account)
      other_account.enable_features!('shopify_integration')
      create(:integrations_hook, :shopify, account: other_account, reference_id: 'my-store.myshopify.com')
      allow(Shopify::PendingInstallation).to receive(:claim)
        .with(token: pending_install_token)
        .and_return(pending_installation)
      allow(pending_installation).to receive(:release!)

      expect do
        post "/api/v1/accounts/#{account.id}/integrations/shopify/complete_install",
             params: { pending_install_token: pending_install_token },
             headers: admin.create_new_auth_token,
             as: :json
      end.not_to change(Integrations::Hook, :count)

      expect(pending_installation).to have_received(:release!)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to eq('This Shopify store is already connected')
    end

    it 'does not claim an install while Shopify is disabled' do
      InstallationConfig.where(name: 'ENABLE_SHOPIFY_INTEGRATION').first_or_initialize.update!(value: false)
      expect(Shopify::PendingInstallation).not_to receive(:claim)

      post "/api/v1/accounts/#{account.id}/integrations/shopify/complete_install",
           params: { pending_install_token: pending_install_token },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/integrations/shopify' do
    let(:admin) { create(:user, account: account, role: :administrator) }

    before do
      create(:integrations_hook, :shopify, account: account)
    end

    context 'when it is an administrator' do
      it 'deletes a Shopify integration with no storefront widget configured' do
        graphql_client = instance_double(ShopifyAPI::Clients::Graphql::Admin)
        allow(ShopifyAPI::Clients::Graphql::Admin).to receive(:new).and_return(graphql_client)
        allow(graphql_client).to receive(:query).with(
          query: Shopify::StorefrontWidget::INSTALLATION_QUERY,
          variables: { namespace: 'chatwoot', key: 'website_token' }
        ).and_return(ShopifyAPIResponse.new('data' => { 'currentAppInstallation' => { 'id' => 'gid://shopify/AppInstallation/123' } }))

        expect do
          delete "/api/v1/accounts/#{account.id}/integrations/shopify",
                 headers: admin.create_new_auth_token,
                 as: :json
        end.to change { account.hooks.count }.by(-1)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized and keeps the integration' do
        expect do
          delete "/api/v1/accounts/#{account.id}/integrations/shopify",
                 headers: agent.create_new_auth_token,
                 as: :json
        end.not_to(change { account.hooks.count })

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/integrations/shopify",
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
