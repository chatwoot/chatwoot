require 'rails_helper'

RSpec.describe 'Webhooks API', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:webhook) { create(:webhook, account: account, inbox: inbox, url: 'https://hello.com') }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/<account_id>/webhooks' do
    context 'when it is an authenticated agent' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/webhooks",
            headers: agent.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin user' do
      it 'gets all webhook' do
        get "/api/v1/accounts/#{account.id}/webhooks",
            headers: administrator.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['payload']['webhooks'].count).to eql account.webhooks.count
      end
    end
  end

  describe 'POST /api/v1/accounts/<account_id>/webhooks' do
    context 'when it is an authenticated agent' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/webhooks",
             headers: agent.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin user' do
      it 'creates webhook' do
        post "/api/v1/accounts/#{account.id}/webhooks",
             params: { account_id: account.id, inbox_id: inbox.id, url: 'https://hello.com' },
             headers: administrator.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:success)

        expect(JSON.parse(response.body)['payload']['webhook']['url']).to eql 'https://hello.com'
      end

      it 'throws error when invalid url provided' do
        post "/api/v1/accounts/#{account.id}/webhooks",
             params: { account_id: account.id, inbox_id: inbox.id, url: 'javascript:alert(1)' },
             headers: administrator.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['message']).to eql 'Url is invalid'
      end

      it 'throws error if subscription events are invalid' do
        post "/api/v1/accounts/#{account.id}/webhooks",
             params: { url: 'https://hello.com', subscriptions: ['conversation_random_event'] },
             headers: administrator.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['message']).to eql 'Subscriptions Invalid events'
      end

      it 'throws error if subscription events are empty' do
        post "/api/v1/accounts/#{account.id}/webhooks",
             params: { url: 'https://hello.com', subscriptions: [] },
             headers: administrator.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['message']).to eql 'Subscriptions Invalid events'
      end

      it 'use default if subscription events are nil' do
        post "/api/v1/accounts/#{account.id}/webhooks",
             params: { url: 'https://hello.com', subscriptions: nil },
             headers: administrator.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:ok)
        expect(
          JSON.parse(response.body)['payload']['webhook']['subscriptions']
        ).to eql %w[conversation_status_changed conversation_updated conversation_created contact_created contact_updated
                    message_created message_updated webwidget_triggered]
      end
    end
  end

  describe 'PUT /api/v1/accounts/<account_id>/webhooks/:id' do
    context 'when it is an authenticated agent' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/webhooks/#{webhook.id}",
            headers: agent.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin user' do
      it 'updates webhook' do
        put "/api/v1/accounts/#{account.id}/webhooks/#{webhook.id}",
            params: { url: 'https://hello.com' },
            headers: administrator.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['payload']['webhook']['url']).to eql 'https://hello.com'
      end
    end
  end

  describe 'DELETE /api/v1/accounts/<account_id>/webhooks/:id' do
    context 'when it is an authenticated agent' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/webhooks/#{webhook.id}",
               headers: agent.create_new_auth_token,
               as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin user' do
      it 'deletes webhook' do
        delete "/api/v1/accounts/#{account.id}/webhooks/#{webhook.id}",
               headers: administrator.create_new_auth_token,
               as: :json
        expect(response).to have_http_status(:success)
        expect(account.webhooks.count).to be 0
      end
    end
  end
end
