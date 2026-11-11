require 'rails_helper'

RSpec.describe 'Webhooks API', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:webhook) { create(:webhook, account: account, inbox: inbox, url: 'https://hello.com', name: 'My Webhook') }
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
        expect(response.parsed_body['payload']['webhooks'].count).to eql account.webhooks.count
      end
    end

    context 'when api_and_webhooks feature is disabled' do
      it 'allows session authenticated admins to manage webhooks' do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        account.disable_features!('api_and_webhooks')
        get "/api/v1/accounts/#{account.id}/webhooks",
            headers: administrator.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:success)
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

        expect(response.parsed_body['payload']['webhook']['url']).to eql 'https://hello.com'
      end

      it 'rejects a future inbox ID before it can disclose another account inbox' do
        victim_account = create(:account)
        headers = administrator.create_new_auth_token
        next_inbox_id = inbox.id + 1

        expect do
          post "/api/v1/accounts/#{account.id}/webhooks",
               params: { webhook: { inbox_id: next_inbox_id, url: 'https://hello.com' } },
               headers: headers, as: :json
        end.not_to change(Webhook, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        victim_inbox = create(:inbox, account: victim_account, name: 'Private future inbox')
        expect(victim_inbox.id).to eq(next_inbox_id)

        get "/api/v1/accounts/#{account.id}/webhooks", headers: headers, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.fetch('payload').fetch('webhooks')).to be_empty
      end

      it 'rejects a foreign inbox without creating a webhook or disclosing its name' do
        victim_inbox = create(:inbox, name: 'Private victim inbox')

        expect do
          post "/api/v1/accounts/#{account.id}/webhooks",
               params: { webhook: { inbox_id: victim_inbox.id, url: 'https://hello.com' } },
               headers: administrator.create_new_auth_token, as: :json
        end.not_to change(Webhook, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['message']).to include('Inbox must belong to the same account as the webhook')
        expect(response.parsed_body.to_s).not_to include(victim_inbox.name)
      end

      it 'creates account-wide webhooks without an inbox' do
        post "/api/v1/accounts/#{account.id}/webhooks",
             params: { webhook: { url: 'https://hello.com' } },
             headers: administrator.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(account.webhooks.last.inbox).to be_nil
      end

      it 'creates webhook with name' do
        post "/api/v1/accounts/#{account.id}/webhooks",
             params: { account_id: account.id, inbox_id: inbox.id, url: 'https://hello.com', name: 'My Webhook' },
             headers: administrator.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:success)

        expect(response.parsed_body['payload']['webhook']['name']).to eql 'My Webhook'
      end

      it 'throws error when invalid url provided' do
        post "/api/v1/accounts/#{account.id}/webhooks",
             params: { account_id: account.id, inbox_id: inbox.id, url: 'javascript:alert(1)' },
             headers: administrator.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['message']).to eql 'Url is invalid'
      end

      it 'throws error if subscription events are invalid' do
        post "/api/v1/accounts/#{account.id}/webhooks",
             params: { url: 'https://hello.com', subscriptions: ['conversation_random_event'] },
             headers: administrator.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['message']).to eql 'Subscriptions Invalid events'
      end

      it 'throws error if subscription events are empty' do
        post "/api/v1/accounts/#{account.id}/webhooks",
             params: { url: 'https://hello.com', subscriptions: [] },
             headers: administrator.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['message']).to eql 'Subscriptions Invalid events'
      end

      it 'use default if subscription events are nil' do
        post "/api/v1/accounts/#{account.id}/webhooks",
             params: { url: 'https://hello.com', subscriptions: nil },
             headers: administrator.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:ok)
        expect(
          response.parsed_body['payload']['webhook']['subscriptions']
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
      it 'rejects reassignment to a nonexistent inbox and preserves the original webhook' do
        original_inbox_id = webhook.inbox_id
        missing_inbox_id = create(:inbox, account: account).id + 1

        put "/api/v1/accounts/#{account.id}/webhooks/#{webhook.id}",
            params: { webhook: { inbox_id: missing_inbox_id, name: 'Changed' } },
            headers: administrator.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(webhook.reload.inbox_id).to eq(original_inbox_id)
        expect(webhook.name).to eq('My Webhook')
      end

      it 'rejects reassignment to a foreign inbox and preserves the original webhook' do
        victim_inbox = create(:inbox, name: 'Private victim inbox')

        put "/api/v1/accounts/#{account.id}/webhooks/#{webhook.id}",
            params: { webhook: { inbox_id: victim_inbox.id, name: 'Changed' } },
            headers: administrator.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(webhook.reload.inbox_id).to eq(inbox.id)
        expect(webhook.name).to eq('My Webhook')
        expect(response.parsed_body.to_s).not_to include(victim_inbox.name)
      end

      it 'allows reassignment to another inbox in the same account' do
        other_inbox = create(:inbox, account: account)

        put "/api/v1/accounts/#{account.id}/webhooks/#{webhook.id}",
            params: { webhook: { inbox_id: other_inbox.id } },
            headers: administrator.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(webhook.reload.inbox).to eq(other_inbox)
      end

      it 'updates webhook' do
        put "/api/v1/accounts/#{account.id}/webhooks/#{webhook.id}",
            params: { url: 'https://hello.com', name: 'Another Webhook' },
            headers: administrator.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload']['webhook']['url']).to eql 'https://hello.com'
        expect(response.parsed_body['payload']['webhook']['name']).to eql 'Another Webhook'
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
