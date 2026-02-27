require 'rails_helper'

RSpec.describe 'Order Notes API', type: :request do
  let!(:account) { create(:account) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let!(:order) { create(:order, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/orders/:order_id/order_notes' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/orders/#{order.id}/order_notes"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let!(:notes) { create_list(:order_note, 3, order: order) }

      it 'returns all notes for the order' do
        get "/api/v1/accounts/#{account.id}/orders/#{order.id}/order_notes",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json.length).to eq(3)
        expect(json.first).to include('id', 'content', 'order_id', 'created_at')
      end

      it 'returns notes in latest-first order' do
        get "/api/v1/accounts/#{account.id}/orders/#{order.id}/order_notes",
            headers: agent.create_new_auth_token,
            as: :json

        json = response.parsed_body
        timestamps = json.map { |n| n['created_at'] }
        expect(timestamps).to eq(timestamps.sort.reverse)
      end

      it 'returns 404 for non-existent order' do
        get "/api/v1/accounts/#{account.id}/orders/0/order_notes",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/orders/:order_id/order_notes' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/orders/#{order.id}/order_notes",
             params: { order_note: { content: 'Test note' } }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates a note for the order' do
        params = { order_note: { content: 'Customer requested expedited shipping' } }

        expect do
          post "/api/v1/accounts/#{account.id}/orders/#{order.id}/order_notes",
               params: params,
               headers: agent.create_new_auth_token,
               as: :json
        end.to change(OrderNote, :count).by(1)

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json['content']).to eq('Customer requested expedited shipping')
        expect(json['order_id']).to eq(order.id)
        expect(json['user']['id']).to eq(agent.id)
      end

      it 'returns error when content is blank' do
        params = { order_note: { content: '' } }

        post "/api/v1/accounts/#{account.id}/orders/#{order.id}/order_notes",
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/orders/:order_id/order_notes/:id' do
    let!(:note) { create(:order_note, order: order) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/orders/#{order.id}/order_notes/#{note.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'deletes the note' do
        expect do
          delete "/api/v1/accounts/#{account.id}/orders/#{order.id}/order_notes/#{note.id}",
                 headers: agent.create_new_auth_token,
                 as: :json
        end.to change(OrderNote, :count).by(-1)

        expect(response).to have_http_status(:success)
      end

      it 'returns 404 for non-existent note' do
        delete "/api/v1/accounts/#{account.id}/orders/#{order.id}/order_notes/0",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
