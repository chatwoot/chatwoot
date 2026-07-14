require 'rails_helper'

describe Twilio::HealthService do
  include Rails.application.routes.url_helpers

  let(:number_instance) { Twilio::REST::Api::V2010::AccountContext::IncomingPhoneNumberInstance }
  let(:twilio_client) { instance_double(Twilio::REST::Client) }
  let(:numbers_list) { instance_double(Twilio::REST::Api::V2010::AccountContext::IncomingPhoneNumberList) }
  let(:twiml_app) { instance_double(Twilio::REST::Api::V2010::AccountContext::ApplicationContext) }
  let(:channel) { create(:channel_twilio_sms, :with_voice) }
  let(:number) do
    instance_double(number_instance, sms_url: twilio_callback_index_url, sms_method: 'POST',
                                     voice_url: channel.voice_call_webhook_url, voice_method: 'POST',
                                     status_callback: channel.voice_status_webhook_url, status_callback_method: 'POST')
  end

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
    allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
    allow(twilio_client).to receive(:incoming_phone_numbers).and_return(numbers_list)
    allow(numbers_list).to receive(:list).and_return([number])
    allow(twilio_client).to receive(:applications).and_return(twiml_app)
    allow(twiml_app).to receive(:fetch).and_return(
      instance_double(Twilio::REST::Api::V2010::AccountContext::ApplicationInstance,
                      voice_url: twiml_app_voice_url, voice_method: 'POST')
    )
  end

  describe '#perform' do
    context 'when everything is registered' do
      let(:twiml_app_voice_url) { channel.voice_call_webhook_url }

      it 'reports healthy' do
        result = described_class.new(channel: channel).perform

        expect(result[:status]).to eq('healthy')
        expect(result[:webhooks].map { |webhook| webhook[:name] }).to eq(%w[messaging voice voice_status voice_app])
      end
    end

    context 'when the twiml app points at a stale host' do
      let(:twiml_app_voice_url) { 'https://old-host.example.com/twilio/voice/call/15551234567' }

      it 'flags outbound calling as misconfigured even though the number is fine' do
        result = described_class.new(channel: channel).perform

        expect(result[:status]).to eq('misconfigured')
        expect(result[:webhooks]).to include(hash_including(name: 'voice', configured: true),
                                             hash_including(name: 'voice_app', configured: false))
      end
    end
  end
end
