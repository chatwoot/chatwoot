require 'rails_helper'

RSpec.describe 'Twitter Authorization API', type: :request do
  let(:account) { create(:account) }

  describe 'POST /api/v1/accounts/{account.id}/twitter/authorization' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/twitter/authorization"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }
      let(:twitter_client) { double }
      let(:twitter_response) { double }
      let(:raw_response) { double }

      it 'returns unathorized for agent' do
        post "/api/v1/accounts/#{account.id}/twitter/authorization",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates a new authorization and returns the redirect url' do
        allow(Twitty::Facade).to receive(:new).and_return(twitter_client)
        allow(twitter_client).to receive(:request_oauth_token).and_return(twitter_response)
        allow(twitter_response).to receive(:status).and_return('200')
        allow(twitter_response).to receive(:raw_response).and_return(raw_response)
        allow(raw_response).to receive(:body).and_return('oauth_token=test_token')

        post "/api/v1/accounts/#{account.id}/twitter/authorization",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['url']).to include('test_token')
      end
    end
  end
end
