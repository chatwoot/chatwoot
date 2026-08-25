require 'rails_helper'

RSpec.describe 'Google Play Authorization API', type: :request do
  let(:account) { create(:account) }
  let(:url) { "/api/v1/accounts/#{account.id}/google_play/authorization" }

  describe 'POST /api/v1/accounts/{account.id}/google_play/authorization' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post url
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        post url, headers: agent.create_new_auth_token, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }

      before do
        # Stand-in OAuth credentials so the authorize URL is built.
        create(:installation_config, name: 'GOOGLE_OAUTH_CLIENT_ID', value: 'client-id-123', locked: false)
        create(:installation_config, name: 'GOOGLE_OAUTH_CLIENT_SECRET', value: 'client-secret', locked: false)
        GlobalConfig.clear_cache
      end

      it 'returns a redirect URL with the androidpublisher scope' do
        post url,
             params: { app_id: 'com.example.app', inbox_name: 'My App' },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['success']).to be true
        expect(body['url']).to include('client_id=client-id-123')
        expect(body['url']).to include('scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fandroidpublisher')
        expect(body['url']).to include('access_type=offline')
        expect(body['url']).to include('prompt=consent')
        expect(body['url']).to include('google_play%2Fcallback')
      end

      it 'signs the state with the app_id and inbox_name so the callback can decode them' do
        post url,
             params: { app_id: 'com.example.app', inbox_name: 'My App' },
             headers: administrator.create_new_auth_token,
             as: :json

        state = CGI.parse(URI(response.parsed_body['url']).query)['state'].first
        decoded = Rails.application.message_verifier('google_play_oauth').verify(state).with_indifferent_access

        expect(decoded[:account_id]).to eq(account.id)
        expect(decoded[:app_id]).to eq('com.example.app')
        expect(decoded[:inbox_name]).to eq('My App')
      end
    end
  end
end
