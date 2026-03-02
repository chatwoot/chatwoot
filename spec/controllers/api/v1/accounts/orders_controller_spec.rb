require 'rails_helper'

RSpec.describe 'Orders API', type: :request do
  let!(:account) { create(:account) }
  let!(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/{account.id}/orders' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/orders"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let!(:orders) { create_list(:order, 3, account: account) }

      it 'returns all orders with pagination meta' do
        get "/api/v1/accounts/#{account.id}/orders",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json['payload'].length).to eq(3)
        expect(json['meta']['count']).to eq(3)
        expect(json['meta']['current_page']).to eq(1)
      end

      it 'paginates results' do
        create_list(:order, 16, account: account)

        get "/api/v1/accounts/#{account.id}/orders",
            params: { page: 1 },
            headers: agent.create_new_auth_token,
            as: :json

        json = response.parsed_body
        expect(json['payload'].length).to eq(15)
        expect(json['meta']['count']).to eq(19) # 3 + 16

        get "/api/v1/accounts/#{account.id}/orders",
            params: { page: 2 },
            headers: agent.create_new_auth_token,
            as: :json

        json = response.parsed_body
        expect(json['payload'].length).to eq(4)
      end

      it 'filters by status' do
        create(:order, :paid, account: account)

        get "/api/v1/accounts/#{account.id}/orders",
            params: { status: 'paid' },
            headers: agent.create_new_auth_token,
            as: :json

        json = response.parsed_body
        expect(json['payload']).to all(include('status' => 'paid'))
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/orders/:id' do
    let!(:order) { create(:order, :with_items, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/orders/#{order.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns the order with items' do
        get "/api/v1/accounts/#{account.id}/orders/#{order.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json['id']).to eq(order.id)
        expect(json['external_payment_id']).to eq(order.external_payment_id)
        expect(json['status']).to eq(order.status)
        expect(json['items']).to be_present
        expect(json['contact']).to be_present
        expect(json['conversation']).to be_present
      end

      it 'returns 404 for non-existent order' do
        get "/api/v1/accounts/#{account.id}/orders/0",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/orders/search' do
    let!(:order) { create(:order, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/orders/search", params: { q: 'test' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'searches by external_payment_id' do
        get "/api/v1/accounts/#{account.id}/orders/search",
            params: { q: order.external_payment_id, sort: '-created_at' },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json['payload'].length).to eq(1)
        expect(json['payload'][0]['id']).to eq(order.id)
      end

      it 'returns no content when q is missing' do
        get "/api/v1/accounts/#{account.id}/orders/search",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:no_content)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/orders/:id/cancel' do
    context 'when it is an unauthenticated user' do
      let!(:order) { create(:order, account: account) }

      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/orders/#{order.id}/cancel"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'cancels a pending order' do
        order = create(:order, account: account, status: :pending)

        patch "/api/v1/accounts/#{account.id}/orders/#{order.id}/cancel",
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json['status']).to eq('cancelled')
        expect(order.reload.status).to eq('cancelled')
      end

      it 'cancels an initiated order' do
        order = create(:order, :initiated, account: account)

        patch "/api/v1/accounts/#{account.id}/orders/#{order.id}/cancel",
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(order.reload.status).to eq('cancelled')
      end

      it 'returns error when cancelling a paid order' do
        order = create(:order, :paid, account: account)

        patch "/api/v1/accounts/#{account.id}/orders/#{order.id}/cancel",
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json['error']).to include('paid')
      end

      it 'returns error when cancelling a failed order' do
        order = create(:order, :failed, account: account)

        patch "/api/v1/accounts/#{account.id}/orders/#{order.id}/cancel",
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns 404 for non-existent order' do
        patch "/api/v1/accounts/#{account.id}/orders/0/cancel",
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
