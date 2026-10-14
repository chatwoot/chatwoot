require 'rails_helper'

RSpec.describe Call do
  describe 'telling rung phones the ring is over' do
    let(:account) { create(:account) }
    let(:call) { create(:call, conversation: create(:conversation, account: account)) }

    before do
      account.enable_features!('mobile_voice_push')
      call.update!(ring_state: { 'rung_devices' => { 'apns_voip' => [], 'fcm' => ['android-1'] } })
    end

    it 'enqueues a cancel push when a ringing call is answered' do
      expect { call.update!(status: 'in_progress') }.to have_enqueued_job(Voice::VoipPushJob).with(call.id, 'cancel')
    end

    it 'enqueues a cancel push when a ringing call is missed' do
      expect { call.update!(status: 'no_answer') }.to have_enqueued_job(Voice::VoipPushJob).with(call.id, 'cancel')
    end

    it 'enqueues a cancel push for devices the ring recorded after this copy of the call was loaded' do
      call.update!(ring_state: {})
      stale = described_class.find(call.id)
      described_class.where(id: call.id).update_all(ring_state: { 'rung_devices' => { 'fcm' => ['android-1'] } }) # rubocop:disable Rails/SkipsModelValidations

      expect { stale.update!(status: 'in_progress') }.to have_enqueued_job(Voice::VoipPushJob).with(call.id, 'cancel')
    end

    it 'does not enqueue for a change that is not a status change' do
      expect { call.update!(meta: call.meta.merge('note' => 'x')) }.not_to have_enqueued_job(Voice::VoipPushJob)
    end

    it 'does not enqueue when the call was never rung on a phone' do
      call.update!(ring_state: {})

      expect { call.update!(status: 'no_answer') }.not_to have_enqueued_job(Voice::VoipPushJob)
    end

    it 'does not enqueue for a transition that does not start from ringing' do
      call.update!(status: 'in_progress')

      expect { call.update!(status: 'completed') }.not_to have_enqueued_job(Voice::VoipPushJob).with(call.id, 'cancel')
    end
  end

  describe 'recording a missed call' do
    let(:account) { create(:account) }
    let(:rang) { { 'ring_recipient_ids' => [] } }
    let(:call) { create(:call, conversation: create(:conversation, account: account), ring_state: rang) }

    it 'enqueues the missed-call notification when an inbound ring is not answered' do
      expect { call.update!(status: 'no_answer') }.to have_enqueued_job(Voice::MissedCallNotificationJob).with(call.id)
    end

    it 'enqueues it for a call created and ended in one transaction, when its end arrived first' do
      conversation = create(:conversation, account: account)

      expect do
        ActiveRecord::Base.transaction do
          create(:call, conversation: conversation, ring_state: rang).update!(status: 'no_answer')
        end
      end.to have_enqueued_job(Voice::MissedCallNotificationJob)
    end

    it 'enqueues it when the caller hangs up during the ring and the provider reports the call completed' do
      expect { call.update!(status: 'completed') }.to have_enqueued_job(Voice::MissedCallNotificationJob).with(call.id)
    end

    it 'does not for a call an agent answered' do
      call.update!(status: 'in_progress', accepted_by_agent: create(:user, account: account), accepted_broadcast_at: Time.zone.now.to_i)

      expect { call.update!(status: 'completed') }.not_to have_enqueued_job(Voice::MissedCallNotificationJob)
    end

    it 'does not for a Twilio call an agent joined that ended before its broadcast was marked' do
      call.update!(status: 'in_progress', accepted_by_agent: create(:user, account: account), started_at: Time.current)

      expect { call.update!(status: 'completed') }.not_to have_enqueued_job(Voice::MissedCallNotificationJob)
    end

    it 'enqueues it for a Twilio call an agent claimed but never joined' do
      call.update!(accepted_by_agent: create(:user, account: account))

      expect { call.update!(status: 'completed') }.to have_enqueued_job(Voice::MissedCallNotificationJob).with(call.id)
    end

    it 'does not for a WhatsApp call an agent answered' do
      call.update!(provider: :whatsapp, status: 'in_progress', accepted_by_agent: create(:user, account: account))

      expect { call.update!(status: 'completed') }.not_to have_enqueued_job(Voice::MissedCallNotificationJob)
    end

    it 'does not for a declined call' do
      expect { call.update!(status: 'rejected') }.not_to have_enqueued_job(Voice::MissedCallNotificationJob)
    end

    it 'does not for an outbound call nobody picked up' do
      call.update!(direction: :outgoing)

      expect { call.update!(status: 'no_answer') }.not_to have_enqueued_job(Voice::MissedCallNotificationJob)
    end

    it 'does not for a call that rang no phones' do
      call.update!(ring_state: {})

      expect { call.update!(status: 'no_answer') }.not_to have_enqueued_job(Voice::MissedCallNotificationJob)
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

  describe 'agent legs' do
    let(:call) { create(:call, conversation: create(:conversation)) }

    it 'records an agent connection as on its way in while the call is live' do
      expect(call.open_agent_leg!('CA-1')).to be(true)
      expect(call.reload.agent_legs.dig('CA-1', 'state')).to eq('joining')
    end

    it 'refuses a connection to a call that has ended' do
      call.update!(status: 'completed')

      expect(call.open_agent_leg!('CA-1')).to be(false)
      expect(call.reload.agent_legs).to be_empty
    end

    it 'keeps a joined connection joined when its instructions are asked for again' do
      call.with_lock { call.record_agent_leg!('CA-1', 'joined') }

      expect(call.open_agent_leg!('CA-1')).to be(true)
      expect(call.reload.agent_legs.dig('CA-1', 'state')).to eq('joined')
    end

    it 'refuses a repeated request for a connection that has already left' do
      call.with_lock { call.record_agent_leg!('CA-1', 'gone') }

      expect(call.open_agent_leg!('CA-1')).to be(false)
      expect(call.reload.agent_legs.dig('CA-1', 'state')).to eq('gone')
    end

    it 'gives up only the place its own attempt held when a connection opens' do
      own = described_class.pending_agent_leg('attempt-1')
      newer = described_class.pending_agent_leg('attempt-2')
      call.with_lock do
        call.record_agent_leg!(own, 'joining')
        call.record_agent_leg!(newer, 'joining')
      end

      call.open_agent_leg!('CA-1', attempt: 'attempt-1')

      expect(call.reload.agent_legs.keys).to contain_exactly(newer, 'CA-1')
    end

    it 'keeps a leg gone when a late callback for it arrives' do
      call.with_lock { call.record_agent_leg!('CA-1', 'gone') }
      call.with_lock { call.record_agent_leg!('CA-1', 'joined') }

      expect(call.reload.agent_legs.dig('CA-1', 'state')).to eq('gone')
    end

    it 'keeps other meta written alongside' do
      call.merge_meta!('provider_status' => 'ringing')
      call.with_lock { call.record_agent_leg!('CA-1', 'joining') }

      expect(call.reload).to have_attributes(provider_status: 'ringing')
    end
  end
end
