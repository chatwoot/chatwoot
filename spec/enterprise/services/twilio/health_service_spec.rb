require 'rails_helper'

describe Twilio::HealthService do
  include Rails.application.routes.url_helpers

  let(:number_instance) { Twilio::REST::Api::V2010::AccountContext::IncomingPhoneNumberInstance }
  let(:twilio_client) { instance_double(Twilio::REST::Client) }
  let(:numbers_list) { instance_double(Twilio::REST::Api::V2010::AccountContext::IncomingPhoneNumberList) }
  let(:twiml_app) { instance_double(Twilio::REST::Api::V2010::AccountContext::ApplicationContext) }
  let(:channel) { create(:channel_twilio_sms, :with_voice) }
  let(:trunk_sid) { nil }
  let(:voice_application_sid) { nil }
  let(:number_voice_url) { channel.voice_call_webhook_url }
  let(:number) do
    instance_double(number_instance, sid: 'PN123', phone_number: channel.phone_number, friendly_name: 'Support line',
                                     capabilities: { 'voice' => true, 'sms' => true, 'mms' => true },
                                     sms_url: twilio_callback_index_url, sms_method: 'POST', sms_application_sid: nil,
                                     voice_url: number_voice_url, voice_method: 'POST',
                                     status_callback: channel.voice_status_webhook_url, status_callback_method: 'POST',
                                     trunk_sid: trunk_sid, voice_application_sid: voice_application_sid)
  end

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
    allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
    allow(twilio_client).to receive(:incoming_phone_numbers).and_return(numbers_list)
    allow(twilio_client).to receive(:api).and_return(
      instance_double(Twilio::REST::Api,
                      accounts: instance_double(Twilio::REST::Api::V2010::AccountContext,
                                                fetch: instance_double(Twilio::REST::Api::V2010::AccountInstance,
                                                                       sid: 'AC123', friendly_name: 'Acme Support',
                                                                       status: 'active', type: 'Full')))
    )
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
        expect(result[:voice_enabled]).to be(true)
      end
    end

    context 'when the twiml app points at a stale host' do
      let(:twiml_app_voice_url) { 'https://old-host.example.com/twilio/voice/call/15551234567' }

      it 'flags outbound calling as misconfigured even though the number is fine' do
        result = described_class.new(channel: channel).perform

        expect(result[:status]).to eq('misconfigured')
        expect(result[:webhooks]).to include(hash_including(name: 'voice', configured: true),
                                             hash_including(name: 'voice_app', configured: false, reason: 'url_mismatch'))
      end
    end

    context 'when the number is attached to a sip trunk' do
      let(:twiml_app_voice_url) { channel.voice_call_webhook_url }
      let(:trunk_sid) { 'TK123' }

      it 'flags the inbound voice webhook as overridden even though the url matches' do
        result = described_class.new(channel: channel).perform

        expect(result[:status]).to eq('misconfigured')
        expect(result[:webhooks]).to include(hash_including(name: 'voice', configured: false, reason: 'overridden_by_trunk'))
      end
    end

    context 'when a foreign twiml app is attached to the number' do
      let(:twiml_app_voice_url) { channel.voice_call_webhook_url }
      let(:voice_application_sid) { 'APsomeoneelse' }

      it 'flags the inbound voice webhook as overridden' do
        expect(described_class.new(channel: channel).perform[:webhooks])
          .to include(hash_including(name: 'voice', configured: false, reason: 'overridden_by_application'))
      end
    end

    context 'when our own twiml app is attached to the number' do
      let(:twiml_app_voice_url) { channel.voice_call_webhook_url }
      let(:voice_application_sid) { channel.twiml_app_sid }
      # Twilio ignores this once the application takes over inbound routing.
      let(:number_voice_url) { nil }

      it 'leaves the inbound voice webhook healthy because the app points back at us' do
        expect(described_class.new(channel: channel).perform[:status]).to eq('healthy')
      end

      it 'drops the number level voice check that twilio would ignore' do
        names = described_class.new(channel: channel).perform[:webhooks].pluck(:name)

        expect(names).to contain_exactly('messaging', 'voice_status', 'voice_app')
      end
    end

    context 'when the twiml app was deleted in twilio' do
      let(:twiml_app_voice_url) { channel.voice_call_webhook_url }

      before do
        allow(twiml_app).to receive(:fetch).and_raise(
          Twilio::REST::RestError.new('The requested resource was not found', Twilio::Response.new(404, '{"code": 20404}'))
        )
      end

      it 'reports the app as missing instead of failing the whole health check' do
        expect(described_class.new(channel: channel).perform[:webhooks])
          .to include(hash_including(name: 'voice_app', configured: false, reason: 'missing_twiml_app'))
      end
    end

    context 'when the twiml app has not been created' do
      let(:twiml_app_voice_url) { channel.voice_call_webhook_url }

      before { allow(channel).to receive(:twiml_app_sid).and_return(nil) }

      it 'reports outbound calling as unavailable' do
        expect(described_class.new(channel: channel).perform[:webhooks])
          .to include(hash_including(name: 'voice_app', configured: false, reason: 'missing_twiml_app'))
      end

      it 'still checks the number level voice webhook' do
        expect(described_class.new(channel: channel).perform[:webhooks])
          .to include(hash_including(name: 'voice'))
      end
    end
  end
end
