require 'rails_helper'

describe Integrations::Pathors::AccessTokenService do
  let(:account) { create(:account) }
  let(:client_id) { 'pathors_client_id' }
  let(:client_secret) { 'pathors_client_secret' }
  let(:token_url) { 'https://api.pathors.com/oauth/token' }

  before do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('PATHORS_API_URL', 'https://api.pathors.com').and_return('https://api.pathors.com')
    allow(GlobalConfigService).to receive(:load).with('PATHORS_OAUTH_CLIENT_ID', nil).and_return(client_id)
    allow(GlobalConfigService).to receive(:load).with('PATHORS_OAUTH_CLIENT_SECRET', nil).and_return(client_secret)
  end

  describe '#access_token' do
    context 'when the access token is still valid' do
      let(:hook) do
        create(
          :integrations_hook,
          :pathors,
          account: account,
          access_token: 'valid_access_token',
          settings: {
            project_id: 'proj_123',
            refresh_token: 'refresh_token',
            token_type: 'Bearer',
            expires_on: 30.minutes.from_now.utc.to_s
          }
        )
      end

      it 'returns the current access token without calling Pathors' do
        stub_request(:post, token_url).to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })

        expect(described_class.new(hook: hook).access_token).to eq('valid_access_token')
        expect(WebMock).not_to have_requested(:post, token_url)
      end
    end

    context 'when the access token is expired' do
      let(:hook) do
        create(
          :integrations_hook,
          :pathors,
          account: account,
          access_token: 'expired_access_token',
          settings: {
            project_id: 'proj_123',
            refresh_token: 'old_refresh_token',
            token_type: 'Bearer',
            expires_on: 1.hour.ago.utc.to_s
          }
        )
      end

      it 'refreshes the token and keeps the project id' do
        stub_request(:post, token_url).to_return(
          status: 200,
          body: {
            access_token: 'new_access_token',
            refresh_token: 'new_refresh_token',
            token_type: 'Bearer',
            expires_in: 7200
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        expect(described_class.new(hook: hook).access_token).to eq('new_access_token')

        hook.reload
        expect(hook.access_token).to eq('new_access_token')
        expect(hook.settings['refresh_token']).to eq('new_refresh_token')
        expect(hook.settings['expires_in']).to eq(7200)
        expect(hook.settings['expires_on']).to be_present
        expect(hook.settings['project_id']).to eq('proj_123')
      end

      it 'falls back to the latest persisted token when the refresh fails' do
        stub_request(:post, token_url).to_return(
          status: 401, body: { error: 'invalid_grant' }.to_json, headers: { 'Content-Type' => 'application/json' }
        )

        Integrations::Hook.find(hook.id).update!(access_token: 'rotated_access_token')

        expect(described_class.new(hook: hook).access_token).to eq('rotated_access_token')
      end

      it 'does not overwrite the stored token on a malformed success response' do
        stub_request(:post, token_url).to_return(
          status: 200,
          body: { refresh_token: 'new_refresh_token', token_type: 'Bearer', expires_in: 7200 }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        expect(described_class.new(hook: hook).access_token).to eq('expired_access_token')

        hook.reload
        expect(hook.access_token).to eq('expired_access_token')
        expect(hook.settings['refresh_token']).to eq('old_refresh_token')
      end
    end
  end

  describe '#refresh!' do
    let(:hook) do
      create(
        :integrations_hook,
        :pathors,
        account: account,
        access_token: 'valid_access_token',
        settings: {
          project_id: 'proj_123',
          refresh_token: 'refresh_token',
          expires_on: 30.minutes.from_now.utc.to_s
        }
      )
    end

    it 'refreshes even when the recorded expiry is still in the future' do
      stub_request(:post, token_url).to_return(
        status: 200,
        body: { access_token: 'forced_access_token', refresh_token: 'refresh_token', expires_in: 7200 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

      expect(described_class.new(hook: hook).refresh!).to eq('forced_access_token')
      expect(hook.reload.access_token).to eq('forced_access_token')
    end
  end
end
