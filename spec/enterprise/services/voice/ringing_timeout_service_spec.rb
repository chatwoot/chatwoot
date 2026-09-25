# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::RingingTimeoutService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551239999') }
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:call) { create(:call, conversation: conversation, provider: :whatsapp, status: 'ringing') }
  let(:conference) { instance_double(Voice::Provider::Twilio::ConferenceService, end_conference: nil) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    account.enable_features!('mobile_voice_push')
    allow(Voice::Provider::Twilio::ConferenceService).to receive(:new).and_return(conference)
    allow(ActionCable.server).to receive(:broadcast)
    call.update!(message: Voice::CallMessageBuilder.new(call).perform!)
  end

  describe '.overdue' do
    def ringing(provider, age)
      create(:call, conversation: create(:conversation, account: account, inbox: inbox), provider: provider, status: 'ringing',
                    created_at: age.ago)
    end

    it 'returns Twilio calls ringing for more than 60 s and WhatsApp calls ringing for more than 45 s' do
      overdue_twilio = ringing(:twilio, 61.seconds)
      overdue_whatsapp = ringing(:whatsapp, 46.seconds)
      ringing(:twilio, 59.seconds)
      ringing(:whatsapp, 44.seconds)

      expect(described_class.overdue).to contain_exactly(overdue_twilio, overdue_whatsapp)
    end

    it 'ignores calls that are no longer ringing' do
      old = ringing(:whatsapp, 5.minutes)
      old.update!(status: 'in_progress')

      expect(described_class.overdue).to be_empty
    end

    it 'ignores calls on accounts that do not ring phones' do
      ringing(:whatsapp, 5.minutes)
      account.disable_features!('mobile_voice_push')

      expect(described_class.overdue).to be_empty
    end
  end

  describe '#perform' do
    it 'ends the call as missed' do
      described_class.new(call: call).perform

      call.reload
      expect(call.status).to eq('no_answer')
      expect(call.end_reason).to eq('ring_timeout')
      expect(call.meta['ended_at']).to be_present
    end

    it 'updates the call message and the conversation the way a provider hang-up does' do
      described_class.new(call: call).perform

      expect(call.reload.message.content_attributes.dig('data', 'status')).to eq('no-answer')
      expect(conversation.reload.additional_attributes['call_status']).to eq('no-answer')
    end

    it 'broadcasts voice_call.ended to the account' do
      described_class.new(call: call).perform

      expect(ActionCable.server).to have_received(:broadcast).with(
        "account_#{account.id}", hash_including(event: 'voice_call.ended', data: hash_including(id: call.id, status: 'no-answer'))
      )
    end

    it 'hangs up a Twilio caller still waiting in the conference' do
      call.update!(provider: :twilio)

      described_class.new(call: call).perform

      expect(conference).to have_received(:end_conference)
      expect(call.reload.status).to eq('no_answer')
    end

    it 'still ends the call when Twilio cannot be reached' do
      call.update!(provider: :twilio)
      allow(conference).to receive(:end_conference).and_raise(Twilio::REST::TwilioError)

      described_class.new(call: call).perform

      expect(call.reload.status).to eq('no_answer')
    end

    it 'does not touch a call that was answered in the meantime' do
      call.update!(status: 'in_progress')

      described_class.new(call: call).perform

      expect(call.reload.status).to eq('in_progress')
      expect(ActionCable.server).not_to have_received(:broadcast)
    end

    it 'leaves a late provider end-of-ring with nothing to change' do
      described_class.new(call: call).perform
      described_class.new(call: call).perform

      expect(call.reload.status).to eq('no_answer')
      expect(ActionCable.server).to have_received(:broadcast).once
    end
  end
end
