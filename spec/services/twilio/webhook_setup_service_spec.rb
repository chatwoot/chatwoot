require 'rails_helper'

describe Twilio::WebhookSetupService do
  include Rails.application.routes.url_helpers

  let(:twilio_client) { instance_double(Twilio::REST::Client) }

  before do
    allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
  end

  describe '#perform' do
    context 'with api key authentication' do
      let(:channel_twilio_sms) do
        create(
          :channel_twilio_sms,
          api_key_sid: 'SK1234567890abcdef',
          account_sid: 'AC1234567890abcdef',
          auth_token: 'api-key-token',
          messaging_service_sid: 'MG1234567890abcdef'
        )
      end

      let(:messaging) { instance_double(Twilio::REST::Messaging) }
      let(:services) { instance_double(Twilio::REST::Messaging::V1::ServiceContext) }

      before do
        allow(Twilio::REST::Client).to receive(:new).with(
          'SK1234567890abcdef',
          'api-key-token',
          'AC1234567890abcdef'
        ).and_return(twilio_client)
        allow(twilio_client).to receive(:messaging).and_return(messaging)
        allow(messaging).to receive(:services).with(channel_twilio_sms.messaging_service_sid).and_return(services)
        allow(services).to receive(:update)
      end

      it 'uses API key credentials to initialize twilio client' do
        described_class.new(inbox: channel_twilio_sms.inbox).perform

        expect(services).to have_received(:update)
      end
    end

    context 'with a messaging service sid' do
      let(:channel_twilio_sms) { create(:channel_twilio_sms, :whatsapp) }

      let(:messaging) { instance_double(Twilio::REST::Messaging) }
      let(:services) { instance_double(Twilio::REST::Messaging::V1::ServiceContext) }

      before do
        allow(twilio_client).to receive(:messaging).and_return(messaging)
        allow(messaging).to receive(:services).with(channel_twilio_sms.messaging_service_sid).and_return(services)
        allow(services).to receive(:update)
        allow(twilio_client).to receive(:incoming_phone_numbers)
      end

      it 'updates the messaging service webhook and skips phone number lookup' do
        described_class.new(inbox: channel_twilio_sms.inbox).perform

        expect(services).to have_received(:update)
        expect(twilio_client).not_to have_received(:incoming_phone_numbers)
      end
    end

    context 'with a phone number' do
      let(:channel_twilio_sms) { create(:channel_twilio_sms, :with_phone_number) }

      let(:phone_double) { double }
      let(:phone_record_double) { double }

      before do
        allow(phone_double).to receive(:update)
        allow(phone_record_double).to receive(:sid).and_return('1234')
      end

      it 'logs error if phone_number is not found' do
        allow(twilio_client).to receive(:incoming_phone_numbers).and_return(phone_double)
        allow(phone_double).to receive(:list).and_return([])

        described_class.new(inbox: channel_twilio_sms.inbox).perform

        expect(phone_double).not_to have_received(:update)
      end

      it 'update webhook_url if phone_number is found' do
        allow(twilio_client).to receive(:incoming_phone_numbers).and_return(phone_double)
        allow(phone_double).to receive(:list).and_return([phone_record_double])

        described_class.new(inbox: channel_twilio_sms.inbox).perform

        expect(phone_double).to have_received(:update).with(
          sms_method: 'POST',
          sms_url: twilio_callback_index_url
        )
      end

      it 'strips whatsapp prefix before looking up phone number' do
        phone_channel = create(
          :channel_twilio_sms,
          :with_phone_number,
          :whatsapp,
          phone_number: 'whatsapp:+1234567890',
          messaging_service_sid: nil
        )

        allow(twilio_client).to receive(:incoming_phone_numbers).and_return(phone_double)
        allow(phone_double).to receive(:list).and_return([phone_record_double])
        allow(phone_record_double).to receive(:sid).and_return('1234')

        described_class.new(inbox: phone_channel.inbox).perform

        expect(phone_double).to have_received(:list).with(
          phone_number: '+1234567890'
        )
      end
    end
  end
end
