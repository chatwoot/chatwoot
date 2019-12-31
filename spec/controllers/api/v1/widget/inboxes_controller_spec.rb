require 'rails_helper'

RSpec.describe '/api/v1/widget/inboxes', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'POST /api/v1/widget/inboxes' do
    let(:params) { { website: { website_name: 'test', website_url: 'test.com', widget_color: '#eaeaea' } } }

    context 'when unauthenticated user' do
      it 'returns unauthorized' do
        post '/api/v1/widget/inboxes', params: params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is logged in' do
      context 'with user as administrator' do
        it 'creates inbox and returns website_token' do
          post '/api/v1/widget/inboxes', params: params, headers: admin.create_new_auth_token

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['name']).to eq('test')
          expect(json_response['website_token']).not_to be_empty
        end
      end

      context 'with user as agent' do
        it 'returns unauthorized' do
          post '/api/v1/widget/inboxes',
               params: params,
               headers: agent.create_new_auth_token

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end

  describe 'PATCH /api/v1/widget/inboxes/:id' do
    let(:update_params) { { website: { widget_color: '#eaeaea' } } }

    context 'when unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/widget/inboxes/#{inbox.channel_id}", params: update_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is logged in' do
      context 'with user as administrator' do
        it 'updates website channel' do
          patch "/api/v1/widget/inboxes/#{inbox.channel_id}",
                params: update_params,
                headers: admin.create_new_auth_token

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['widget_color']).to eq('#eaeaea')
        end
      end

      context 'with user as agent' do
        it 'returns unauthorized' do
          patch "/api/v1/widget/inboxes/#{inbox.channel_id}",
                params: update_params,
                headers: agent.create_new_auth_token

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
