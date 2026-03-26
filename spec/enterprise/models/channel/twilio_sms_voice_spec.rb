# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::TwilioSms do
  let(:account) { create(:account) }
  let(:twiml_app_sid) { 'AP1234567890abcdef' }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new).and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: twiml_app_sid))
  end

  describe 'factory' do
    it 'has a valid :with_voice factory' do
      channel = create(:channel_twilio_sms, :with_voice, account: account)
      expect(channel).to be_valid
      expect(channel.voice_enabled?).to be true
    end
  end

  describe 'validations' do
    it 'requires a phone number when voice is enabled' do
      channel = build(:channel_twilio_sms, :with_voice, account: account, phone_number: nil)
      channel.valid?
      expect(channel.errors[:base]).to include('Voice calling requires a phone number and cannot be used with messaging service SID')
    end
  end

  describe '#voice_enabled?' do
    it 'returns true when voice_enabled is set' do
      channel = create(:channel_twilio_sms, :with_voice, account: account)
      expect(channel.voice_enabled?).to be true
    end

    it 'returns false by default' do
      channel = create(:channel_twilio_sms, account: account)
      expect(channel.voice_enabled?).to be false
    end
  end

  describe '#voice_call_webhook_url' do
    it 'returns the webhook URL based on phone number' do
      channel = create(:channel_twilio_sms, :with_voice)
      digits = channel.phone_number.delete_prefix('+')
      expect(channel.voice_call_webhook_url).to include(digits)
    end
  end

  describe '#voice_status_webhook_url' do
    it 'returns the status webhook URL based on phone number' do
      channel = create(:channel_twilio_sms, :with_voice)
      digits = channel.phone_number.delete_prefix('+')
      expect(channel.voice_status_webhook_url).to include(digits)
    end
  end

  describe 'provisioning on create' do
    it 'stores twiml_app_sid from the webhook setup service' do
      channel = create(:channel_twilio_sms, :with_voice, twiml_app_sid: nil)
      expect(channel.twiml_app_sid).to eq(twiml_app_sid)
    end
  end
end
