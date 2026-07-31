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
    allow(GlobalConfigService).to receive(:load)
      .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
      .and_return(true)
  end

  describe 'GET /api/v1/accounts/:account_id/integrations/shopify/orders' do
    before do
      create(:integrations_hook, :shopify, account: account)
    end

    context 'when it is an authenticated user' do
      # rubocop:disable RSpec/AnyInstance
      let(:shopify_client) { instance_double(ShopifyAPI::Clients::Rest::Admin) }

      let(:customers_response) do
        instance_double(
          ShopifyAPIResponse,
          body: { 'customers' => [{ 'id' => '123' }] }
        )
      end

      let(:orders_response) do
        instance_double(
          ShopifyAPIResponse,
          body: {
            'orders' => [{
              'id' => '456',
              'email' => 'test@example.com',
              'created_at' => Time.now.iso8601,
              'total_price' => '100.00',
              'currency' => 'USD',
              'fulfillment_status' => 'fulfilled',
              'financial_status' => 'paid'
            }]
          }
        )
      end

      before do
        allow_any_instance_of(Api::V1::Accounts::Integrations::ShopifyController).to receive(:shopify_client).and_return(shopify_client)

        allow_any_instance_of(Api::V1::Accounts::Integrations::ShopifyController).to receive(:client_id).and_return('test_client_id')
        allow_any_instance_of(Api::V1::Accounts::Integrations::ShopifyController).to receive(:client_secret).and_return('test_client_secret')

        allow(shopify_client).to receive(:get).with(
          path: 'customers/search.json',
          query: { query: "email:#{contact.email} OR phone:#{contact.phone_number}", fields: 'id,email,phone' }
        ).and_return(customers_response)

        allow(shopify_client).to receive(:get).with(
          path: 'orders.json',
          query: { customer_id: '123', status: 'any', fields: 'id,email,created_at,total_price,currency,fulfillment_status,financial_status' }
        ).and_return(orders_response)
      end

      it 'returns orders for the contact' do
        get "/api/v1/accounts/#{account.id}/integrations/shopify/orders",
            params: { contact_id: contact.id },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to have_key('orders')
        expect(response.parsed_body['orders'].length).to eq(1)
        expect(response.parsed_body['orders'][0]['id']).to eq('456')
      end

      it 'returns error when contact has no email or phone' do
        contact_without_info = create(:contact, account: account)

        get "/api/v1/accounts/#{account.id}/integrations/shopify/orders",
            params: { contact_id: contact_without_info.id },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Contact information missing')
      end

      it 'returns empty array when no customers found' do
        empty_customers_response = instance_double(
          ShopifyAPIResponse,
          body: { 'customers' => [] }
        )

        allow(shopify_client).to receive(:get).with(
          path: 'customers/search.json',
          query: { query: "email:#{contact.email} OR phone:#{contact.phone_number}", fields: 'id,email,phone' }
        ).and_return(empty_customers_response)

        get "/api/v1/accounts/#{account.id}/integrations/shopify/orders",
            params: { contact_id: contact.id },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['orders']).to eq([])
      end
      # rubocop:enable RSpec/AnyInstance
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
        allow(GlobalConfigService).to receive(:load)
          .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
          .and_return(false)

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
    let(:admin) { create(:user, account: account, role: :administrator) }
    let(:pending_install_token) { SecureRandom.hex(16) }
    let(:pending_installation) do
      instance_double(
        Shopify::PendingInstallation,
        data: {
          'access_token' => 'shopify-access-token',
          'shop' => 'my-store.myshopify.com',
          'scope' => 'read_customers,read_orders'
        }
      )
    end

    it 'creates the Shopify hook and consumes the pending install' do
      allow(Shopify::PendingInstallation).to receive(:claim)
        .with(token: pending_install_token, account_id: account.id)
        .and_return(pending_installation)
      allow(pending_installation).to receive(:consume!) do
        expect(account.hooks.exists?(app_id: 'shopify')).to be(true)
      end

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
        status: 'enabled',
        settings: { 'scope' => 'read_customers,read_orders' }
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

    it 'returns an error when the pending install cannot be claimed' do
      allow(Shopify::PendingInstallation).to receive(:claim)
        .and_raise(Shopify::PendingInstallation::InvalidToken, 'Invalid or expired install token')

      post "/api/v1/accounts/#{account.id}/integrations/shopify/complete_install",
           params: { pending_install_token: pending_install_token },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to eq('Invalid or expired install token')
    end

    it 'rolls back the hook when claim consumption fails' do
      allow(Shopify::PendingInstallation).to receive(:claim)
        .with(token: pending_install_token, account_id: account.id)
        .and_return(pending_installation)
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
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to eq('Install token claim has expired')
    end

    it 'rolls back the hook when claim finalization raises an infrastructure error' do
      allow(Shopify::PendingInstallation).to receive(:claim)
        .with(token: pending_install_token, account_id: account.id)
        .and_return(pending_installation)
      allow(pending_installation).to receive(:consume!).and_raise(Redis::CannotConnectError, 'Redis unavailable')
      allow(pending_installation).to receive(:release!)

      expect do
        post "/api/v1/accounts/#{account.id}/integrations/shopify/complete_install",
             params: { pending_install_token: pending_install_token },
             headers: admin.create_new_auth_token,
             as: :json
      end.not_to change(Integrations::Hook, :count)

      expect(pending_installation).to have_received(:release!)
      expect(response).to have_http_status(:internal_server_error)
    end

    it 'preserves the hook when claim finalization has an unknown commit outcome' do
      allow(Shopify::PendingInstallation).to receive(:claim)
        .with(token: pending_install_token, account_id: account.id)
        .and_return(pending_installation)
      allow(pending_installation).to receive(:consume!)
        .and_raise(Shopify::PendingInstallation::CommitOutcomeUnknown, 'Install token consumption outcome is unknown')
      expect(pending_installation).not_to receive(:release!)

      expect do
        post "/api/v1/accounts/#{account.id}/integrations/shopify/complete_install",
             params: { pending_install_token: pending_install_token },
             headers: admin.create_new_auth_token,
             as: :json
      end.to change(Integrations::Hook, :count).by(1)

      expect(response).to have_http_status(:internal_server_error)
    end

    it 'releases the pending install when hook creation fails' do
      create(:integrations_hook, :shopify, account: account)
      allow(Shopify::PendingInstallation).to receive(:claim).and_return(pending_installation)
      allow(pending_installation).to receive(:release!)
      expect(pending_installation).not_to receive(:consume!)

      post "/api/v1/accounts/#{account.id}/integrations/shopify/complete_install",
           params: { pending_install_token: pending_install_token },
           headers: admin.create_new_auth_token,
           as: :json

      expect(pending_installation).to have_received(:release!)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'does not read a pending install when Shopify is disabled' do
      allow(GlobalConfigService).to receive(:load)
        .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
        .and_return(false)

      expect(Shopify::PendingInstallation).not_to receive(:claim)

      post "/api/v1/accounts/#{account.id}/integrations/shopify/complete_install",
           params: { pending_install_token: SecureRandom.hex(16) },
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
      it 'deletes the shopify integration' do
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
