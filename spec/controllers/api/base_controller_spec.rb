require 'rails_helper'

RSpec.describe 'API Base', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }

  describe 'request with api_access_token for user' do
    context 'when accessing an account scoped resource' do
      let!(:admin) { create(:user, :administrator, account: account) }
      let!(:conversation) { create(:conversation, account: account) }

      it 'sets Current attributes for the request and then returns the response' do
        # expect Current.account_user is set to the admin's account_user
        allow(Current).to receive(:user=).and_call_original
        allow(Current).to receive(:account=).and_call_original
        allow(Current).to receive(:account_user=).and_call_original

        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
            headers: { api_access_token: admin.access_token.token },
            as: :json

        expect(Current).to have_received(:user=).with(admin).at_least(:once)
        expect(Current).to have_received(:account=).with(account).at_least(:once)
        expect(Current).to have_received(:account_user=).with(admin.account_users.first).at_least(:once)

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['id']).to eq(conversation.display_id)
      end
    end

    context 'when it is an invalid api_access_token' do
      it 'returns unauthorized' do
        get '/api/v1/profile',
            headers: { api_access_token: 'invalid' },
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is a valid api_access_token' do
      it 'returns current user information' do
        get '/api/v1/profile',
            headers: { api_access_token: user.access_token.token },
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['id']).to eq(user.id)
        expect(json_response['email']).to eq(user.email)
      end
    end
  end

  describe 'request with api_access_token for a super admin' do
    before do
      user.update!(type: 'SuperAdmin')
    end

    context 'when its a valid api_access_token' do
      it 'returns current user information' do
        get '/api/v1/profile',
            headers: { api_access_token: user.access_token.token },
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['id']).to eq(user.id)
        expect(json_response['email']).to eq(user.email)
      end
    end
  end

  describe 'request with api_access_token for bot' do
    let!(:agent_bot) { create(:agent_bot) }
    let!(:inbox) { create(:inbox, account: account) }
    let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user, status: 'pending') }

    context 'when it is an unauthorized url' do
      it 'returns unauthorized' do
        get '/api/v1/profile',
            headers: { api_access_token: agent_bot.access_token.token },
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is a accessible url' do
      it 'returns success' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status",
             headers: { api_access_token: agent_bot.access_token.token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.status).to eq('open')
      end
    end

    context 'when the account is suspended' do
      it 'returns 401 unauthorized' do
        account.update!(status: :suspended)

        post "/api/v1/accounts/#{account.id}/canned_responses",
             headers: { api_access_token: user.access_token.token },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      # this exception occured in a client instance (DoubleRender error)
      it 'will not throw exception if user does not have access to suspended account' do
        user_with_out_access = create(:user)
        account.update!(status: :suspended)

        post "/api/v1/accounts/#{account.id}/canned_responses",
             headers: { api_access_token: user_with_out_access.access_token.token },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
