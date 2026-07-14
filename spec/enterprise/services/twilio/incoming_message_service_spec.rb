require 'rails_helper'

describe Twilio::IncomingMessageService do
  # Voice channels keep the API key secret in api_key_secret, unlike SMS channels which reuse auth_token.
  describe '#perform' do
    let(:voice_channel) { create(:channel_twilio_sms, :with_voice) }
    let(:params_with_attachment) do
      {
        SmsSid: 'SMvoice',
        From: '+12345',
        To: voice_channel.phone_number,
        AccountSid: voice_channel.account_sid,
        Body: 'mms on a voice inbox',
        NumMedia: '1',
        MediaContentType0: 'image/jpeg',
        MediaUrl0: 'https://chatwoot-assets.local/sample.png'
      }
    end

    before do
      allow(Twilio::VoiceWebhookSetupService).to receive(:new)
        .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
      stub_request(:get, 'https://chatwoot-assets.local/sample.png')
        .to_return(status: 200, body: 'image data', headers: { 'Content-Type' => 'image/png' })
    end

    it 'downloads the media using the api key secret, not the account auth token' do
      allow(Down).to receive(:download).and_call_original

      described_class.new(params: params_with_attachment).perform

      expect(Down).to have_received(:download).with(
        'https://chatwoot-assets.local/sample.png',
        http_basic_authentication: [voice_channel.api_key_sid, voice_channel.api_key_secret]
      )
    end
  end
end
