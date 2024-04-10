require 'rails_helper'

RSpec.describe Microsoft::RefreshOauthTokenService do
  let(:access_token) { SecureRandom.hex }
  let(:refresh_token) { SecureRandom.hex }
  let(:expires_on) { Time.zone.now + 3600 }

  let!(:microsoft_email_channel) do
    create(:channel_email, provider_config: { access_token: access_token, refresh_token: refresh_token, expires_on: expires_on })
  end
  let(:new_tokens) { { access_token: access_token, refresh_token: refresh_token, expires_at: expires_on.to_i, token_type: 'bearer' } }

  describe '#access_token' do
    context 'when token is not expired' do
      it 'returns the existing access token' do
        expect(described_class.new(channel: microsoft_email_channel).access_token).to eq(access_token)
        expect(microsoft_email_channel.reload.provider_config['refresh_token']).to eq(refresh_token)
      end
    end

    context 'when token is expired' do
      let(:expires_on) { 1.minute.from_now }

      before do
        stub_request(:post, 'https://login.microsoftonline.com/common/oauth2/v2.0/token').with(
          body: { 'grant_type' => 'refresh_token', 'refresh_token' => refresh_token }
        ).to_return(status: 200, body: new_tokens.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'fetches new access token and refresh tokens' do
        microsoft_email_channel.provider_config['expires_on'] = Time.zone.now - 3600
        microsoft_email_channel.save!

        expect(described_class.new(channel: microsoft_email_channel).access_token).not_to eq(access_token)
        expect(microsoft_email_channel.reload.provider_config['access_token']).to eq(new_tokens[:access_token])
        expect(microsoft_email_channel.reload.provider_config['refresh_token']).to eq(new_tokens[:refresh_token])
        expect(microsoft_email_channel.reload.provider_config['expires_on']).to eq(Time.at(new_tokens[:expires_at]).utc.to_s)
      end
    end

    context 'when refresh token is not present in provider config and access token is expired' do
      it 'throws an error' do
        microsoft_email_channel.update(provider_config: {
                                         access_token: access_token,
                                         expires_on: expires_on - 3600
                                       })
        expect do
          described_class.new(channel: microsoft_email_channel).access_token
        end.to raise_error(RuntimeError, 'A refresh_token is not available')
      end
    end
  end
end
