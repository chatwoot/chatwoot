require 'rails_helper'

RSpec.describe Google::RefreshOauthTokenService do
  let!(:google_channel) { create(:channel_email, :microsoft_email) }
  let!(:google_channel_with_expired_token) do
    create(
      :channel_email, :microsoft_email, provider_config: {
        expires_on: Time.zone.now - 3600,
        access_token: SecureRandom.hex,
        refresh_token: SecureRandom.hex
      }
    )
  end

  let(:new_tokens) do
    {
      access_token: SecureRandom.hex,
      refresh_token: SecureRandom.hex,
      expires_at: (Time.zone.now + 3600).to_i,
      token_type: 'bearer'
    }
  end

  context 'when token is not expired' do
    it 'returns the existing access token' do
      service = described_class.new(channel: google_channel)

      expect(service.access_token).to eq(google_channel.provider_config['access_token'])
      expect(google_channel.reload.provider_config['refresh_token']).to eq(google_channel.provider_config['refresh_token'])
    end
  end

  describe 'on expired token or invalid expiry' do
    before do
      stub_request(:post, 'https://oauth2.googleapis.com/token').with(
        body: { 'grant_type' => 'refresh_token', 'refresh_token' => google_channel_with_expired_token.provider_config['refresh_token'] }
      ).to_return(status: 200, body: new_tokens.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    context 'when token is invalid' do
      it 'fetches new access token and refresh tokens' do
        with_modified_env GOOGLE_OAUTH_CLIENT_ID: SecureRandom.uuid, GOOGLE_OAUTH_CLIENT_SECRET: SecureRandom.hex do
          provider_config = google_channel_with_expired_token.provider_config
          service = described_class.new(channel: google_channel_with_expired_token)
          expect(service.access_token).not_to eq(provider_config['access_token'])

          new_provider_config = google_channel_with_expired_token.reload.provider_config
          expect(new_provider_config['access_token']).to eq(new_tokens[:access_token])
          expect(new_provider_config['refresh_token']).to eq(new_tokens[:refresh_token])
          expect(new_provider_config['expires_on']).to eq(Time.at(new_tokens[:expires_at]).utc.to_s)
        end
      end
    end

    context 'when expiry time is missing' do
      it 'fetches new access token and refresh tokens' do
        with_modified_env GOOGLE_OAUTH_CLIENT_ID: SecureRandom.uuid, GOOGLE_OAUTH_CLIENT_SECRET: SecureRandom.hex do
          google_channel_with_expired_token.provider_config['expires_on'] = nil
          google_channel_with_expired_token.save!
          provider_config = google_channel_with_expired_token.provider_config
          service = described_class.new(channel: google_channel_with_expired_token)
          expect(service.access_token).not_to eq(provider_config['access_token'])

          new_provider_config = google_channel_with_expired_token.reload.provider_config
          expect(new_provider_config['access_token']).to eq(new_tokens[:access_token])
          expect(new_provider_config['refresh_token']).to eq(new_tokens[:refresh_token])
          expect(new_provider_config['expires_on']).to eq(Time.at(new_tokens[:expires_at]).utc.to_s)
        end
      end
    end
  end

  context 'when refresh token is not present in provider config and access token is expired' do
    it 'throws an error' do
      with_modified_env GOOGLE_OAUTH_CLIENT_ID: SecureRandom.uuid, GOOGLE_OAUTH_CLIENT_SECRET: SecureRandom.hex do
        google_channel.update!(
          provider_config: {
            access_token: SecureRandom.hex,
            expires_on: Time.zone.now - 3600
          }
        )

        expect do
          described_class.new(channel: google_channel).access_token
        end.to raise_error(RuntimeError, 'A refresh_token is not available')
      end
    end
  end
end
