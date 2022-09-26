require 'rails_helper'

RSpec.describe 'Custom Filters API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/accounts/{account.id}/custom_filters' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/custom_filters"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:user) { create(:user, account: account) }
      let!(:custom_filter) { create(:custom_filter, user: user, account: account) }

      it 'returns all custom_filter related to the user' do
        get "/api/v1/accounts/#{account.id}/custom_filters",
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = JSON.parse(response.body)
        expect(response_body.first['name']).to eq(custom_filter.name)
        expect(response_body.first['query']).to eq(custom_filter.query)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/custom_filters/:id' do
    let(:user) { create(:user, account: account) }
    let!(:custom_filter) { create(:custom_filter, user: user, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/custom_filters/#{custom_filter.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'shows the custom filter' do
        get "/api/v1/accounts/#{account.id}/custom_filters/#{custom_filter.id}",
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(custom_filter.name)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/custom_filters' do
    let(:payload) { { custom_filter: { name: 'vip-customers', filter_type: 'conversation', query: { labels: ['vip-customers'] } } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/custom_filters", params: payload }.not_to change(CustomFilter, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:user) { create(:user, account: account) }

      it 'creates the filter' do
        expect do
          post "/api/v1/accounts/#{account.id}/custom_filters", headers: user.create_new_auth_token,
                                                                params: payload
        end.to change(CustomFilter, :count).by(1)

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['name']).to eq 'vip-customers'
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/custom_filters/:id' do
    let(:payload) { { custom_filter: { name: 'vip-customers', filter_type: 'contact', query: { labels: ['vip-customers'] } } } }
    let(:user) { create(:user, account: account) }
    let!(:custom_filter) { create(:custom_filter, user: user, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/custom_filters/#{custom_filter.id}",
            params: payload

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates the custom filter' do
        patch "/api/v1/accounts/#{account.id}/custom_filters/#{custom_filter.id}",
              headers: user.create_new_auth_token,
              params: payload,
              as: :json

        expect(response).to have_http_status(:success)
        expect(custom_filter.reload.name).to eq('vip-customers')
        expect(custom_filter.reload.filter_type).to eq('contact')
        expect(custom_filter.reload.query['labels']).to eq(['vip-customers'])
      end

      it 'prevents the update of custom filter of another user/account' do
        other_account = create(:account)
        other_user = create(:user, account: other_account)
        other_custom_filter = create(:custom_filter, user: other_user, account: other_account)

        patch "/api/v1/accounts/#{account.id}/custom_filters/#{other_custom_filter.id}",
              headers: user.create_new_auth_token,
              params: payload,
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/custom_filters/:id' do
    let(:user) { create(:user, account: account) }
    let!(:custom_filter) { create(:custom_filter, user: user, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/custom_filters/#{custom_filter.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin user' do
      it 'deletes custom filter if it is attached to the current user and account' do
        delete "/api/v1/accounts/#{account.id}/custom_filters/#{custom_filter.id}",
               headers: user.create_new_auth_token,
               as: :json
        expect(response).to have_http_status(:no_content)
        expect(user.custom_filters.count).to be 0
      end
    end
  end
end
