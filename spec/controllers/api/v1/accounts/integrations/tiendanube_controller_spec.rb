require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Integrations::TiendanubeController', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:client_id) { 'test_client_id' }
  let(:client_secret) { 'test_client_secret' }
  let(:store_id) { '123456' }

  before do
    allow(GlobalConfigService).to receive(:load).with('TIENDANUBE_CLIENT_ID', nil).and_return(client_id)
    allow(GlobalConfigService).to receive(:load).with('TIENDANUBE_CLIENT_SECRET', nil).and_return(client_secret)
    allow(ENV).to receive(:fetch).with('FRONTEND_URL', '').and_return('http://localhost:3000')
  end

  describe 'POST /api/v1/accounts/:account_id/integrations/tiendanube/auth' do
    context 'when authenticated' do
      it 'returns OAuth authorization URL' do
        post "/api/v1/accounts/#{account.id}/integrations/tiendanube/auth",
             headers: agent.create_new_auth_token,
             params: { store_id: store_id },
             as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['redirect_url']).to include("https://#{store_id}.mitiendanube.com/apps/authorize/token")
        expect(json_response['redirect_url']).to include("client_id=#{client_id}")
      end

      it 'returns error when store_id is missing' do
        post "/api/v1/accounts/#{account.id}/integrations/tiendanube/auth",
             headers: agent.create_new_auth_token,
             params: {},
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Store ID is required')
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/integrations/tiendanube/orders' do
    let!(:hook) do
      create(:integrations_hook,
             account: account,
             app_id: 'tiendanube',
             access_token: 'test_token',
             reference_id: store_id)
    end
    let(:contact) { create(:contact, account: account, email: 'customer@example.com', phone_number: '+1234567890') }

    context 'when integration is connected' do
      before do
        stub_request(:get, %r{https://api.tiendanube.com/v1/#{store_id}/customers/search})
          .to_return(
            status: 200,
            body: { customers: [{ id: '1', email: 'customer@example.com' }] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:get, %r{https://api.tiendanube.com/v1/#{store_id}/orders})
          .to_return(
            status: 200,
            body: {
              orders: [
                {
                  id: '100',
                  number: '1001',
                  status: 'open',
                  total: '99.99',
                  currency: 'USD',
                  created_at: '2024-01-01T00:00:00Z'
                }
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns orders for the contact' do
        get "/api/v1/accounts/#{account.id}/integrations/tiendanube/orders",
            headers: agent.create_new_auth_token,
            params: { contact_id: contact.id },
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['orders']).to be_an(Array)
        expect(json_response['orders'].first['id']).to eq('100')
        expect(json_response['orders'].first['admin_url']).to include('mitiendanube.com/admin/orders')
      end

      it 'returns empty array when no customers found' do
        stub_request(:get, %r{https://api.tiendanube.com/v1/#{store_id}/customers/search})
          .to_return(
            status: 200,
            body: { customers: [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        get "/api/v1/accounts/#{account.id}/integrations/tiendanube/orders",
            headers: agent.create_new_auth_token,
            params: { contact_id: contact.id },
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['orders']).to eq([])
      end

      it 'returns error when contact has no email or phone' do
        contact_without_info = create(:contact, account: account, email: nil, phone_number: nil)

        get "/api/v1/accounts/#{account.id}/integrations/tiendanube/orders",
            headers: agent.create_new_auth_token,
            params: { contact_id: contact_without_info.id },
            as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Contact information missing')
      end

      it 'caches orders for 5 minutes' do
        # First request - should hit API
        get "/api/v1/accounts/#{account.id}/integrations/tiendanube/orders",
            headers: agent.create_new_auth_token,
            params: { contact_id: contact.id },
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['cached']).to be false
        expect(json_response['orders'].first['id']).to eq('100')

        # Second request - should use cache
        get "/api/v1/accounts/#{account.id}/integrations/tiendanube/orders",
            headers: agent.create_new_auth_token,
            params: { contact_id: contact.id },
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['cached']).to be true
        expect(json_response['orders'].first['id']).to eq('100')
      end
    end

    context 'when API returns 401' do
      before do
        stub_request(:get, %r{https://api.tiendanube.com/v1/#{store_id}/customers/search})
          .to_return(status: 401)
      end

      it 'returns error message' do
        get "/api/v1/accounts/#{account.id}/integrations/tiendanube/orders",
            headers: agent.create_new_auth_token,
            params: { contact_id: contact.id },
            as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to include('Invalid or expired access token')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/integrations/tiendanube' do
    let!(:hook) do
      create(:integrations_hook,
             account: account,
             app_id: 'tiendanube',
             access_token: 'test_token',
             reference_id: store_id)
    end

    it 'deletes the integration hook' do
      expect do
        delete "/api/v1/accounts/#{account.id}/integrations/tiendanube",
               headers: agent.create_new_auth_token,
               as: :json
      end.to change(Integrations::Hook, :count).by(-1)

      expect(response).to have_http_status(:success)
    end

    it 'clears cached orders when disconnecting' do
      contact = create(:contact, account: account, email: 'test@example.com')
      cache_key = "tiendanube_orders_#{account.id}_#{contact.id}"
      
      # Set some cached data
      Rails.cache.write(cache_key, [{ id: '1' }])
      expect(Rails.cache.exist?(cache_key)).to be true

      delete "/api/v1/accounts/#{account.id}/integrations/tiendanube",
             headers: agent.create_new_auth_token,
             as: :json

      expect(response).to have_http_status(:success)
      expect(Rails.cache.exist?(cache_key)).to be false
    end
  end

  describe 'multi-tenancy' do
    let(:other_account) { create(:account) }
    let(:other_agent) { create(:user, account: other_account, role: :agent) }
    let!(:hook) do
      create(:integrations_hook,
             account: account,
             app_id: 'tiendanube',
             access_token: 'test_token',
             reference_id: store_id)
    end

    it 'prevents access to other account integrations' do
      expect do
        delete "/api/v1/accounts/#{other_account.id}/integrations/tiendanube",
               headers: agent.create_new_auth_token,
               as: :json
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
