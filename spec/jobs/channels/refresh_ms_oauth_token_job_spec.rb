require 'rails_helper'

RSpec.describe Channels::RefreshMsOauthTokenJob, type: :job do
  let(:access_token) { SecureRandom.hex }
  let(:refresh_token) { SecureRandom.hex }
  let(:expires_on) { Time.zone.now + 3600 }
  let(:graph_endpoint) { 'https://graph.microsoft.com' }
  let(:azure_ad_endpoint) { 'https://login.microsoftonline.com' }
  let!(:microsoft_email_channel) do
    create(:channel_email, provider_config: { access_token: access_token, refresh_token: refresh_token, expires_on: expires_on })
  end
  before do
    stub_request(:post, "#{azure_ad_endpoint}/common/oauth2/v2.0/token").to_return(
      body: { 'access_token' => access_token, 'refresh_token' => refresh_token, 'expires_on' => expires_on }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )


    stub_request(:post, "https://login.microsoftonline.com/common/oauth2/v2.0/token").with(
      body: {"grant_type"=>"refresh_token", "refresh_token"=>refresh_token},
      headers: {
        'Accept'=>'*/*',
        'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization'=>'Basic Og==',
        'Content-Type'=>'application/x-www-form-urlencoded',
        'User-Agent'=>'Faraday v1.10.0'
      }).
      to_return(status: 200, body: "", headers: {})
  end

  describe '#refresh_token' do
    it 'when refresh token present' do
      response = described_class.new.refresh_tokens(microsoft_email_channel, microsoft_email_channel.provider_config)
      expect(response['refresh_token']).to be_present
      expect(response['access_token']).to be_present
    end

    it 'when refresh token not present' do
      microsoft_email_channel.update(provider_config: {
                                       access_token: access_token,
                                       expires_on: expires_on
                                     })
      expect do
        described_class.new.refresh_tokens(microsoft_email_channel, microsoft_email_channel.reload.provider_config)
      end.to raise_error(RuntimeError, 'A refresh_token is not available')
    end
  end
end
