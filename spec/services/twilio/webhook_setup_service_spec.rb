require 'rails_helper'

describe Twilio::WebhookSetupService do
  include Rails.application.routes.url_helpers

  let(:twilio_client) { instance_double(Twilio::REST::Client) }
  let(:inbox) { instance_double(Inbox, channel: channel_twilio_sms) }

  before do
    allow(channel_twilio_sms).to receive(:client).and_return(twilio_client)
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
        allow(twilio_client).to receive(:messaging).and_return(messaging)
        allow(messaging).to receive(:services).with(channel_twilio_sms.messaging_service_sid).and_return(services)
        allow(services).to receive(:update)
      end

      it 'uses the channel client so credential handling stays consistent' do
        described_class.new(inbox: inbox).perform

        expect(channel_twilio_sms).to have_received(:client)
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
        described_class.new(inbox: inbox).perform

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
        allow(Rails.logger).to receive(:warn)

        described_class.new(inbox: inbox).perform

        expect(phone_double).not_to have_received(:update)
        expect(Rails.logger).to have_received(:warn).with("TWILIO_PHONE_NUMBER_NOT_FOUND: #{channel_twilio_sms.phone_number}")
      end

      it 'update webhook_url if phone_number is found' do
        allow(twilio_client).to receive(:incoming_phone_numbers).and_return(phone_double)
        allow(phone_double).to receive(:list).and_return([phone_record_double])

        described_class.new(inbox: inbox).perform

        expect(phone_double).to have_received(:update).with(
          sms_method: 'POST',
          sms_url: twilio_callback_index_url
        )
      end
    end

    context 'with a WhatsApp phone number' do
      let(:channel_twilio_sms) do
        create(
          :channel_twilio_sms,
          :with_phone_number,
          :whatsapp,
          phone_number: 'whatsapp:+1234567890',
          messaging_service_sid: nil
        )
      end

      let(:messaging) { instance_double(Twilio::REST::Messaging) }
      let(:messaging_v2) { instance_double(Twilio::REST::Messaging::V2) }
      let(:senders) { instance_double(Twilio::REST::Messaging::V2::ChannelsSenderList) }
      let(:sender_context) { instance_double(Twilio::REST::Messaging::V2::ChannelsSenderContext) }
      let(:sender) do
        instance_double(
          Twilio::REST::Messaging::V2::ChannelsSenderInstance,
          sid: 'XE1234567890abcdef',
          sender_id: 'whatsapp:+1234567890'
        )
      end

      before do
        allow(twilio_client).to receive(:messaging).and_return(messaging)
        allow(messaging).to receive(:v2).and_return(messaging_v2)
        allow(messaging_v2).to receive(:channels_senders).with(no_args).and_return(senders)
        allow(senders).to receive(:list).with(channel: 'whatsapp').and_return([sender])
        allow(messaging_v2).to receive(:channels_senders).with(sender.sid).and_return(sender_context)
        allow(sender_context).to receive(:update)
        allow(twilio_client).to receive(:incoming_phone_numbers)
      end

      it 'updates the matching WhatsApp sender webhook' do
        described_class.new(inbox: inbox).perform

        expect(sender_context).to have_received(:update).with(
          messaging_v2_channels_sender_requests_update: {
            webhook: {
              callback_url: twilio_callback_index_url,
              callback_method: 'POST'
            }
          }
        )
        expect(twilio_client).not_to have_received(:incoming_phone_numbers)
      end

      it 'logs a warning when the WhatsApp sender is not found' do
        allow(senders).to receive(:list).with(channel: 'whatsapp').and_return([])
        allow(Rails.logger).to receive(:warn)

        described_class.new(inbox: inbox).perform

        expect(sender_context).not_to have_received(:update)
        expect(Rails.logger).to have_received(:warn).with('TWILIO_WHATSAPP_SENDER_NOT_FOUND: whatsapp:+1234567890')
      end
    end
  end
end
