require 'rails_helper'

RSpec.describe 'GooglePlay::CallbacksController', type: :request do
  let(:account) { create(:account) }
  let(:code) { SecureRandom.hex(10) }
  let(:state_payload) { { account_id: account.id, app_id: 'com.example.app', inbox_name: 'My App' } }
  let(:state) { Rails.application.message_verifier('google_play_oauth').generate(state_payload, expires_in: 15.minutes) }
  let(:token_response) do
    { access_token: 'play-access-token', refresh_token: 'play-refresh-token', token_type: 'Bearer', expires_in: 3599 }
  end

  before do
    create(:installation_config, name: 'GOOGLE_OAUTH_CLIENT_ID', value: 'client-id-123', locked: false)
    create(:installation_config, name: 'GOOGLE_OAUTH_CLIENT_SECRET', value: 'client-secret', locked: false)
    GlobalConfig.clear_cache
  end

  describe 'GET /google_play/callback' do
    it 'creates the channel + inbox and redirects to the agent assignment page' do
      stub_request(:post, 'https://oauth2.googleapis.com/o/oauth2/token')
        .to_return(status: 200, body: token_response.to_json, headers: { 'Content-Type' => 'application/json' })

      expect do
        get '/google_play/callback', params: { code: code, state: state }
      end.to change(Channel::GooglePlay, :count).by(1)
                                                .and change(Inbox, :count).by(1)

      inbox = Inbox.last
      channel = inbox.channel
      expect(channel.app_id).to eq('com.example.app')
      expect(channel.provider_config).to include('access_token' => 'play-access-token', 'refresh_token' => 'play-refresh-token')
      expect(inbox.name).to eq('My App')
      expect(response).to redirect_to(app_google_play_inbox_agents_url(account_id: account.id, inbox_id: inbox.id))
    end

    it 'redirects to the inbox setup page surfacing the error when Google returns an error param' do
      get '/google_play/callback', params: { error: 'access_denied', state: state }

      expect(Channel::GooglePlay.count).to eq(0)
      expect(response).to redirect_to(app_new_google_play_inbox_url(account_id: account.id, error: 'access_denied'))
    end

    it 'redirects to the inbox setup page with the error when token exchange fails' do
      stub_request(:post, 'https://oauth2.googleapis.com/o/oauth2/token').to_return(status: 400, body: 'invalid')

      get '/google_play/callback', params: { code: code, state: state }

      expect(Channel::GooglePlay.count).to eq(0)
      expect(response.location).to include("/app/accounts/#{account.id}/settings/inboxes/new/google_play")
      expect(response.location).to include('error=')
    end

    it 'falls back to / when the state cannot be decoded' do
      get '/google_play/callback', params: { code: code, state: 'tampered' }
      expect(response).to redirect_to('/')
    end
  end
end
