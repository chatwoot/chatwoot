require 'rails_helper'

describe Integrations::Linear::AccessTokenService do
  let(:account) { create(:account) }
  let(:client_id) { 'linear_client_id' }
  let(:client_secret) { 'linear_client_secret' }

  before do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('LINEAR_CLIENT_ID', nil).and_return(client_id)
    allow(GlobalConfigService).to receive(:load).with('LINEAR_CLIENT_SECRET', nil).and_return(client_secret)
  end

  describe '#access_token' do
    context 'when access token is still valid' do
      let(:hook) do
        create(
          :integrations_hook,
          :linear,
          account: account,
          access_token: 'valid_access_token',
          settings: {
            refresh_token: 'refresh_token',
            token_type: 'Bearer',
            scope: 'read,write',
            expires_on: 30.minutes.from_now.utc.to_s
          }
        )
      end

      it 'returns the current access token' do
        service = described_class.new(hook: hook)

        expect(service.access_token).to eq('valid_access_token')
      end
    end

    context 'when access token is expired and refresh token is present' do
      let(:hook) do
        create(
          :integrations_hook,
          :linear,
          account: account,
          access_token: 'expired_access_token',
          settings: {
            refresh_token: 'old_refresh_token',
            token_type: 'Bearer',
            scope: 'read,write',
            expires_on: 1.hour.ago.utc.to_s
          }
        )
      end

      it 'refreshes the token and persists new values' do
        stub_request(:post, 'https://api.linear.app/oauth/token')
          .to_return(
            status: 200,
            body: {
              access_token: 'new_access_token',
              refresh_token: 'new_refresh_token',
              token_type: 'Bearer',
              expires_in: 7200,
              scope: 'read,write'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        service = described_class.new(hook: hook)

        expect(service.access_token).to eq('new_access_token')
        hook.reload
        expect(hook.access_token).to eq('new_access_token')
        expect(hook.settings['refresh_token']).to eq('new_refresh_token')
        expect(hook.settings['expires_in']).to eq(7200)
        expect(hook.settings['expires_on']).to be_present
      end
    end

    context 'when refresh token is missing and legacy migration is applicable' do
      let(:hook) do
        create(
          :integrations_hook,
          :linear,
          account: account,
          access_token: 'legacy_access_token',
          settings: {
            token_type: 'Bearer',
            scope: 'read,write'
          }
        )
      end

      it 'migrates the legacy token and persists refresh token data' do
        stub_request(:post, 'https://api.linear.app/oauth/migrate_old_token')
          .to_return(
            status: 200,
            body: {
              access_token: 'migrated_access_token',
              refresh_token: 'migrated_refresh_token',
              token_type: 'Bearer',
              expires_in: 7200,
              scope: 'read,write'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        service = described_class.new(hook: hook)

        expect(service.access_token).to eq('migrated_access_token')
        hook.reload
        expect(hook.access_token).to eq('migrated_access_token')
        expect(hook.settings['refresh_token']).to eq('migrated_refresh_token')
        expect(hook.settings['expires_in']).to eq(7200)
        expect(hook.settings['expires_on']).to be_present
      end
    end
  end
end
