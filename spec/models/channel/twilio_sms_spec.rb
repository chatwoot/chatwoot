# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::TwilioSms do
  describe '#has_24_hour_messaging_window?' do
    context 'with medium whatsapp' do
      let!(:whatsapp_channel) { create(:channel_twilio_sms, medium: :whatsapp) }

      it 'returns true' do
        expect(whatsapp_channel.messaging_window_enabled?).to eq true
        expect(whatsapp_channel.name).to eq 'Whatsapp'
        expect(whatsapp_channel.medium).to eq 'whatsapp'
      end
    end

    context 'with medium sms' do
      let!(:sms_channel) { create(:channel_twilio_sms, medium: :sms) }

      it 'returns false' do
        expect(sms_channel.messaging_window_enabled?).to eq false
        expect(sms_channel.name).to eq 'Twilio SMS'
        expect(sms_channel.medium).to eq 'sms'
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
