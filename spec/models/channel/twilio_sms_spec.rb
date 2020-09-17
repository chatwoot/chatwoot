# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::TwilioSms do
  context 'with medium whatsapp' do
    let!(:whatsapp_channel) { create(:channel_twilio_sms, medium: :whatsapp) }

    it 'returns true' do
      expect(whatsapp_channel.has_24_hour_messaging_window?).to eq true
      expect(whatsapp_channel.name).to eq 'Whatsapp'
      expect(whatsapp_channel.medium).to eq 'whatsapp'
    end
  end

  context 'with medium sms' do
    let!(:sms_channel) { create(:channel_twilio_sms, medium: :sms) }

    it 'returns false' do
      expect(sms_channel.has_24_hour_messaging_window?).to eq false
      expect(sms_channel.name).to eq 'Twilio SMS'
      expect(sms_channel.medium).to eq 'sms'
    end
  end
end
