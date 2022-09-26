# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::TwilioSms do
  describe '#has_24_hour_messaging_window?' do
    context 'with medium whatsapp' do
      let!(:whatsapp_channel) { create(:channel_twilio_sms, medium: :whatsapp) }

      it 'returns true' do
        expect(whatsapp_channel.messaging_window_enabled?).to be true
        expect(whatsapp_channel.name).to eq 'Whatsapp'
        expect(whatsapp_channel.medium).to eq 'whatsapp'
      end
    end

    context 'with medium sms' do
      let!(:sms_channel) { create(:channel_twilio_sms, medium: :sms) }

      it 'returns false' do
        expect(sms_channel.messaging_window_enabled?).to be false
        expect(sms_channel.name).to eq 'Twilio SMS'
        expect(sms_channel.medium).to eq 'sms'
      end
    end
  end

  describe '#validations' do
    context 'with phone number blank' do
      let!(:sms_channel) { create(:channel_twilio_sms, medium: :sms, phone_number: nil) }

      it 'allows channel to create with blank phone number' do
        sms_channel_1 = create(:channel_twilio_sms, medium: :sms, phone_number: '')

        expect(sms_channel_1).to be_valid
        expect(sms_channel_1.messaging_service_sid).to be_present
        expect(sms_channel_1.phone_number).to be_blank
        expect(sms_channel.phone_number).to be_nil

        sms_channel_1 = create(:channel_twilio_sms, medium: :sms, phone_number: nil)
        expect(sms_channel_1.phone_number).to be_blank
        expect(sms_channel_1.messaging_service_sid).to be_present
      end

      it 'throws error for whatsapp channel' do
        whatsapp_channel_1 = create(:channel_twilio_sms, medium: :sms, phone_number: '', messaging_service_sid: 'MGec8130512b5dd462cfe03095ec1111ed')
        expect do
          create(:channel_twilio_sms, medium: :whatsapp, phone_number: 'whatsapp', messaging_service_sid: 'MGec8130512b5dd462cfe03095ec1111ed')
        end.to raise_error(ActiveRecord::RecordInvalid) { |error| expect(error.message).to eq 'Validation failed: Phone number must be blank' }

        expect(whatsapp_channel_1).to be_valid
      end
    end
  end

  describe '#send_message' do
    let(:channel) { create(:channel_twilio_sms) }

    let(:twilio_client) { instance_double(Twilio::REST::Client) }
    let(:twilio_messages) { double }

    before do
      allow(::Twilio::REST::Client).to receive(:new).and_return(twilio_client)
      allow(twilio_client).to receive(:messages).and_return(twilio_messages)
    end

    it 'sends via twilio client' do
      expect(twilio_messages).to receive(:create).with(
        messaging_service_sid: channel.messaging_service_sid,
        to: '+15555550111',
        body: 'hello world'
      ).once

      channel.send_message(to: '+15555550111', body: 'hello world')
    end

    context 'with a "from" phone number' do
      let(:channel) { create(:channel_twilio_sms, :with_phone_number) }

      it 'sends via twilio client' do
        expect(twilio_messages).to receive(:create).with(
          from: channel.phone_number,
          to: '+15555550111',
          body: 'hello world'
        ).once

        channel.send_message(to: '+15555550111', body: 'hello world')
      end
    end

    context 'with media urls' do
      it 'supplies a media url' do
        expect(twilio_messages).to receive(:create).with(
          messaging_service_sid: channel.messaging_service_sid,
          to: '+15555550111',
          body: 'hello world',
          media_url: ['https://example.com/1.jpg']
        ).once

        channel.send_message(to: '+15555550111', body: 'hello world', media_url: ['https://example.com/1.jpg'])
      end
    end
  end
end
