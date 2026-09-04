require 'rails_helper'

# Voice channels keep the API key secret in api_key_secret, unlike SMS channels which reuse auth_token.
RSpec.describe Twilio::MediaDownloadService do
  let(:account_sid) { "AC#{'1' * 32}" }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account_sid: account_sid) }
  let(:message_sid) { "MM#{'2' * 32}" }
  let(:media_sid) { "ME#{'3' * 32}" }
  let(:media_url) do
    "https://api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages/#{message_sid}/Media/#{media_sid}"
  end
  let(:cdn_url) { "https://mms.twiliocdn.com/#{media_sid}?Expires=123&Signature=signed" }
  let(:service) do
    described_class.new(
      channel: channel,
      media_url: media_url,
      message_sid: message_sid,
      media_index: 0
    )
  end

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('api.twilio.com').and_return(['54.172.60.0'])
    allow(Resolv).to receive(:getaddresses).with('mms.twiliocdn.com').and_return(['18.65.3.1'])
  end

  it 'authenticates with the api key secret rather than the account auth token' do
    voice_credentials = [channel.api_key_sid, channel.api_key_secret]
    stub_request(:get, media_url)
      .with(basic_auth: voice_credentials)
      .to_return(status: 302, headers: { 'Location' => cdn_url })
    stub_request(:get, cdn_url)
      .with { |request| request.headers['Authorization'].blank? }
      .to_return(status: 200, body: 'image data', headers: { 'Content-Type' => 'image/jpeg' })

    expect(service.perform).to be_present
    expect(a_request(:get, media_url).with(basic_auth: voice_credentials)).to have_been_made.once
  end
end
