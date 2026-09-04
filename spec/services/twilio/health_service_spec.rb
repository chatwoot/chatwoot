require 'rails_helper'

NUMBER_INSTANCE = Twilio::REST::Api::V2010::AccountContext::IncomingPhoneNumberInstance
NUMBER_LIST = Twilio::REST::Api::V2010::AccountContext::IncomingPhoneNumberList

describe Twilio::HealthService do
  include Rails.application.routes.url_helpers

  let(:twilio_client) { instance_double(Twilio::REST::Client) }
  let(:numbers_list) { instance_double(NUMBER_LIST) }
  let(:account_status) { 'active' }
  let(:account_type) { 'Full' }
  let(:twilio_account) do
    instance_double(Twilio::REST::Api::V2010::AccountInstance,
                    sid: 'AC123', friendly_name: 'Acme Support', status: account_status, type: account_type)
  end

  before do
    allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
    allow(twilio_client).to receive(:incoming_phone_numbers).and_return(numbers_list)
    allow(twilio_client).to receive(:api).and_return(
      instance_double(Twilio::REST::Api, accounts: instance_double(Twilio::REST::Api::V2010::AccountContext, fetch: twilio_account))
    )
  end

  describe '#perform' do
    context 'with a phone number' do
      let(:channel) { create(:channel_twilio_sms, :with_phone_number) }
      let(:sms_url) { twilio_callback_index_url }
      let(:sms_method) { 'POST' }
      let(:sms_application_sid) { nil }
      let(:capabilities) { { 'voice' => true, 'sms' => true, 'mms' => true } }
      let(:number) do
        instance_double(NUMBER_INSTANCE, sid: 'PN123', phone_number: channel.phone_number, friendly_name: 'Support line',
                                         capabilities: capabilities, sms_url: sms_url, sms_method: sms_method,
                                         sms_application_sid: sms_application_sid)
      end

      before { allow(numbers_list).to receive(:list).and_return([number]) }

      it 'reports healthy when the messaging webhook points at chatwoot over POST' do
        result = described_class.new(channel: channel).perform

        expect(result[:status]).to eq('healthy')
        expect(result[:webhooks]).to contain_exactly(hash_including(name: 'messaging', configured: true, reason: nil))
      end

      it 'includes the twilio account and sender details' do
        result = described_class.new(channel: channel).perform

        expect(result[:account]).to eq(sid: 'AC123', friendly_name: 'Acme Support', status: 'active', type: 'Full')
        expect(result[:sender]).to include(type: 'phone_number', sid: 'PN123', label: channel.phone_number,
                                           capabilities: { 'voice' => true, 'sms' => true, 'mms' => true })
        expect(result[:voice_enabled]).to be(false)
      end

      context 'when twilio capitalises the capability keys' do
        let(:capabilities) { { 'SMS' => true, 'MMS' => false, 'voice' => false } }

        it 'downcases them so the dashboard can read them' do
          expect(described_class.new(channel: channel).perform[:sender][:capabilities])
            .to eq('sms' => true, 'mms' => false, 'voice' => false)
        end
      end

      context 'when a restricted api key cannot read the account resource' do
        before do
          allow(twilio_client).to receive(:api).and_raise(
            Twilio::REST::RestError.new('Unable to fetch record', Twilio::Response.new(401, '{"code": 20003}'))
          )
        end

        it 'omits account context but still reports the webhooks' do
          result = described_class.new(channel: channel).perform

          expect(result[:account]).to be_nil
          expect(result[:status]).to eq('healthy')
          expect(result[:webhooks].first).to include(name: 'messaging', configured: true)
        end
      end

      context 'when the account lookup fails for a reason other than permissions' do
        before do
          allow(twilio_client).to receive(:api).and_raise(
            Twilio::REST::RestError.new('Too many requests', Twilio::Response.new(429, '{"code": 20429}'))
          )
        end

        it 'raises rather than reporting healthy with the account unchecked' do
          expect { described_class.new(channel: channel).perform }.to raise_error(Twilio::REST::RestError)
        end
      end

      context 'when the account is suspended' do
        let(:account_status) { 'suspended' }

        it 'surfaces the account status' do
          expect(described_class.new(channel: channel).perform[:account][:status]).to eq('suspended')
        end

        it 'reports misconfigured even though the webhooks are correct' do
          expect(described_class.new(channel: channel).perform[:status]).to eq('misconfigured')
        end
      end

      context 'when the number cannot send sms' do
        let(:capabilities) { { 'voice' => true, 'sms' => false, 'mms' => false } }

        it 'reports misconfigured because the inbox cannot receive its traffic' do
          expect(described_class.new(channel: channel).perform[:status]).to eq('misconfigured')
        end
      end

      context 'when the messaging webhook points elsewhere' do
        let(:sms_url) { 'https://demo.twilio.com/welcome/sms/reply' }

        it 'reports a url mismatch with the current url' do
          result = described_class.new(channel: channel).perform

          expect(result[:status]).to eq('misconfigured')
          expect(result[:webhooks].first).to include(configured: false, reason: 'url_mismatch',
                                                     expected: twilio_callback_index_url, actual: sms_url)
        end
      end

      context 'when the messaging webhook is not set at all' do
        let(:sms_url) { '' }

        it 'reports it as unset rather than mismatched' do
          expect(described_class.new(channel: channel).perform[:webhooks].first)
            .to include(configured: false, reason: 'not_set', actual: nil)
        end
      end

      context 'when the messaging webhook is registered as GET' do
        let(:sms_method) { 'GET' }

        it 'reports the http method rather than a url mismatch' do
          expect(described_class.new(channel: channel).perform[:webhooks].first)
            .to include(configured: false, reason: 'wrong_http_method', method: 'GET')
        end
      end

      context 'when a twiml app is attached to the number' do
        let(:sms_application_sid) { 'AP123' }

        it 'flags the override because twilio ignores sms_url' do
          expect(described_class.new(channel: channel).perform[:webhooks].first)
            .to include(configured: false, reason: 'overridden_by_application')
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
                        sid: channel.messaging_service_sid, friendly_name: 'Acme Messaging',
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
        expect(result[:sender]).to eq(type: 'messaging_service', sid: channel.messaging_service_sid, label: 'Acme Messaging')
      end

      context 'when the service still defers to the number webhook' do
        let(:use_inbound_webhook_on_number) { true }

        it 'reports misconfigured because twilio would bypass our inbound url' do
          result = described_class.new(channel: channel).perform

          expect(result[:status]).to eq('misconfigured')
          expect(result[:webhooks].first).to include(reason: 'overridden_by_number')
        end
      end
    end
  end
end
