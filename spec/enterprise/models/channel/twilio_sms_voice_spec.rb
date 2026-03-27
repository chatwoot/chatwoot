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

  describe 'teardown on disable' do
    let(:channel) { create(:channel_twilio_sms, :with_voice, account: account) }
    let(:app_context) { double('app_context') }
    let(:twilio_client) { instance_double(Twilio::REST::Client) }

    before do
      allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
      allow(twilio_client).to receive(:applications).with(channel.twiml_app_sid).and_return(app_context)
      allow(app_context).to receive(:delete)
    end

    it 'deletes the TwiML app and clears voice credentials' do
      original_twiml_sid = channel.twiml_app_sid
      channel.update!(voice_enabled: false)

      expect(twilio_client).to have_received(:applications).with(original_twiml_sid)
      expect(app_context).to have_received(:delete)
      expect(channel.reload.twiml_app_sid).to be_nil
      expect(channel.reload.api_key_secret).to be_nil
    end

    it 'preserves api_key_sid' do
      channel.update!(voice_enabled: false)
      expect(channel.reload.api_key_sid).to be_present
    end

    it 'does not fail if Twilio API errors' do
      allow(app_context).to receive(:delete).and_raise(Twilio::REST::RestError.new('Not found', double(status_code: 404, body: {})))

      expect { channel.update!(voice_enabled: false) }.not_to raise_error
      expect(channel.reload.twiml_app_sid).to be_nil
      expect(channel.reload.api_key_secret).to be_nil
    end
  end
end
