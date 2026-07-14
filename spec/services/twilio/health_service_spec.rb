require 'rails_helper'

NUMBER_INSTANCE = Twilio::REST::Api::V2010::AccountContext::IncomingPhoneNumberInstance
NUMBER_LIST = Twilio::REST::Api::V2010::AccountContext::IncomingPhoneNumberList

describe Twilio::HealthService do
  include Rails.application.routes.url_helpers

  let(:twilio_client) { instance_double(Twilio::REST::Client) }
  let(:numbers_list) { instance_double(NUMBER_LIST) }

  before do
    allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
    allow(twilio_client).to receive(:incoming_phone_numbers).and_return(numbers_list)
  end

  describe '#perform' do
    context 'with a phone number' do
      let(:channel) { create(:channel_twilio_sms, :with_phone_number) }
      let(:sms_url) { twilio_callback_index_url }
      let(:sms_method) { 'POST' }

      before do
        allow(numbers_list).to receive(:list).and_return([instance_double(NUMBER_INSTANCE, sms_url: sms_url, sms_method: sms_method)])
      end

      it 'reports healthy when the messaging webhook points at chatwoot over POST' do
        result = described_class.new(channel: channel).perform

        expect(result[:status]).to eq('healthy')
        expect(result[:webhooks]).to contain_exactly(hash_including(name: 'messaging', configured: true))
      end

      context 'when the messaging webhook points elsewhere' do
        let(:sms_url) { 'https://demo.twilio.com/welcome/sms/reply' }

        it 'reports misconfigured with the current url' do
          result = described_class.new(channel: channel).perform

          expect(result[:status]).to eq('misconfigured')
          expect(result[:webhooks].first).to include(configured: false, expected: twilio_callback_index_url, actual: sms_url)
        end
      end

      context 'when the number is missing from the twilio account' do
        before { allow(numbers_list).to receive(:list).and_return([]) }

        it 'raises' do
          expect { described_class.new(channel: channel).perform }.to raise_error(/was not found/)
        end
      end
    end

    context 'with a messaging service' do
      let(:channel) { create(:channel_twilio_sms) }
      let(:messaging) { instance_double(Twilio::REST::Messaging) }
      let(:services) { instance_double(Twilio::REST::Messaging::V1::ServiceContext) }
      let(:use_inbound_webhook_on_number) { false }
      let(:service) do
        instance_double(Twilio::REST::Messaging::V1::ServiceInstance,
                        inbound_request_url: twilio_callback_index_url, inbound_method: 'POST',
                        use_inbound_webhook_on_number: use_inbound_webhook_on_number)
      end

      before do
        allow(twilio_client).to receive(:messaging).and_return(messaging)
        allow(messaging).to receive(:services).with(channel.messaging_service_sid).and_return(services)
        allow(services).to receive(:fetch).and_return(service)
      end

      it 'checks the inbound request url of the messaging service' do
        result = described_class.new(channel: channel).perform

        expect(result[:status]).to eq('healthy')
        expect(result[:webhooks].first).to include(name: 'messaging', configured: true)
      end

      context 'when the service still defers to the number webhook' do
        let(:use_inbound_webhook_on_number) { true }

        it 'reports misconfigured because twilio would bypass our inbound url' do
          expect(described_class.new(channel: channel).perform[:status]).to eq('misconfigured')
        end
      end
    end

    context 'with voice enabled' do
      let(:channel) { create(:channel_twilio_sms, :with_voice) }
      let(:sms_url) { nil }
      let(:number) do
        instance_double(NUMBER_INSTANCE, sms_url: sms_url, sms_method: 'POST',
                                         voice_url: channel.voice_call_webhook_url, voice_method: 'POST',
                                         status_callback: channel.voice_status_webhook_url, status_callback_method: 'POST')
      end
      let(:twiml_app) { instance_double(Twilio::REST::Api::V2010::AccountContext::ApplicationContext) }

      before do
        allow(Twilio::VoiceWebhookSetupService).to receive(:new)
          .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
        allow(numbers_list).to receive(:list).and_return([number])
        allow(twilio_client).to receive(:applications).and_return(twiml_app)
        allow(twiml_app).to receive(:fetch).and_return(
          instance_double(Twilio::REST::Api::V2010::AccountContext::ApplicationInstance,
                          voice_url: twiml_app_voice_url, voice_method: 'POST')
        )
      end

      context 'when everything is registered' do
        let(:sms_url) { twilio_callback_index_url }
        let(:twiml_app_voice_url) { channel.voice_call_webhook_url }

        it 'reports healthy' do
          result = described_class.new(channel: channel).perform

          expect(result[:status]).to eq('healthy')
          expect(result[:webhooks].map { |webhook| webhook[:name] }).to eq(%w[messaging voice voice_status voice_app])
        end
      end

      context 'when the twiml app points at a stale host' do
        let(:sms_url) { twilio_callback_index_url }
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
end
