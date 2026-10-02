require 'rails_helper'

RSpec.describe Call do
  describe 'telling rung phones the ring is over' do
    let(:account) { create(:account) }
    let(:call) { create(:call, conversation: create(:conversation, account: account)) }

    before do
      account.enable_features!('mobile_voice_push')
      call.update!(meta: { 'rung_devices' => { 'apns_voip' => [], 'fcm' => ['android-1'] } })
    end

    it 'enqueues a cancel push when a ringing call is answered' do
      expect { call.update!(status: 'in_progress') }.to have_enqueued_job(Voice::VoipPushJob).with(call.id, 'cancel')
    end

    it 'enqueues a cancel push when a ringing call is missed' do
      expect { call.update!(status: 'no_answer') }.to have_enqueued_job(Voice::VoipPushJob).with(call.id, 'cancel')
    end

    it 'does not enqueue for a change that is not a status change' do
      expect { call.update!(meta: call.meta.merge('note' => 'x')) }.not_to have_enqueued_job(Voice::VoipPushJob)
    end

    it 'does not enqueue when the call was never rung on a phone' do
      call.update!(meta: {})

      expect { call.update!(status: 'no_answer') }.not_to have_enqueued_job(Voice::VoipPushJob)
    end

    it 'does not enqueue for a transition that does not start from ringing' do
      call.update!(status: 'in_progress')

      expect { call.update!(status: 'completed') }.not_to have_enqueued_job(Voice::VoipPushJob).with(call.id, 'cancel')
    end
  end

  describe '#push_event_data' do
    let(:account) { create(:account) }
    let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551239999') }
    let(:inbox) { channel.inbox }
    let(:contact) { create(:contact, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
    let(:call) { create(:call, account: account, inbox: inbox, conversation: conversation, contact: contact) }

    it 'renders without raising for a call whose contact no longer exists' do
      call
      contact.delete

      data = call.reload.push_event_data
      expect(data[:from_number]).to be_nil
    end
  end
end
