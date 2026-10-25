# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::Conference::Manager do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551239999') }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:call) { create(:call, conversation: conversation, status: 'in_progress', accepted_by_agent: agent, started_at: 1.minute.ago) }
  let(:conference) { instance_double(Voice::Provider::Twilio::ConferenceService, agents_remain?: false, end_conference: nil, terminate_call: nil) }
  let(:agent_label) { "agent-#{agent.id}-account-#{account.id}" }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    real = Voice::Provider::Twilio::ConferenceService.new(call: call)
    allow(conference).to receive(:complete_unless_agent_joining) do |leaving_call_sid:, since:|
      real.complete_unless_agent_joining(leaving_call_sid: leaving_call_sid, since: since)
    end
    allow(Voice::Provider::Twilio::ConferenceService).to receive(:new).and_return(conference)
  end

  def with_legs(legs)
    call.update!(meta: call.meta.merge('agent_legs' => legs.transform_values { |state| { 'state' => state, 'at' => Time.zone.now.to_i } }))
  end

  def leave(label, call_sid: 'CA-leaving')
    described_class.new(call: call, event: 'leave', participant_label: label, participant_call_sid: call_sid).process
  end

  describe 'an agent leg leaving a live call' do
    it 'completes the call and hangs up the contact when no other agent remains' do
      leave(agent_label)

      expect(call.reload.status).to eq('completed')
      expect(conference).to have_received(:agents_remain?).with(leaving_call_sid: 'CA-leaving')
      expect(conference).to have_received(:end_conference)
    end

    it 'ends the live call when the leave holds a copy loaded while it still rang' do
      call.update!(status: 'ringing')
      stale = Call.find(call.id)
      call.update!(status: 'in_progress')

      described_class.new(call: stale, event: 'leave', participant_label: agent_label, participant_call_sid: 'CA-leaving').process

      expect(call.reload.status).to eq('completed')
      expect(conference).to have_received(:end_conference)
    end

    it 'hangs up an outbound contact still being dialled when the last agent leaves' do
      call.update!(direction: :outgoing)

      leave(agent_label)

      expect(call.reload.status).to eq('completed')
      expect(conference).to have_received(:terminate_call)
    end

    it 'leaves that hang-up to a job when Twilio cannot do it' do
      call.update!(direction: :outgoing)
      allow(conference).to receive(:terminate_call).and_raise(Twilio::REST::TwilioError)

      expect { leave(agent_label) }.to have_enqueued_job(Voice::HangUpContactJob).with(call.id)
    end

    it 'keeps the call live while another agent is still on it' do
      allow(conference).to receive(:agents_remain?).and_return(true)

      leave(agent_label)

      expect(call.reload.status).to eq('in_progress')
      expect(conference).not_to have_received(:end_conference)
    end

    it 'keeps the call live and rechecks by job when Twilio cannot say who is left' do
      allow(conference).to receive(:agents_remain?).and_raise(Twilio::REST::TwilioError)

      expect { leave(agent_label) }.to have_enqueued_job(Voice::EndConferenceJob).with(call.id, leaving_call_sid: 'CA-leaving')
      expect(call.reload.status).to eq('in_progress')
      expect(conference).not_to have_received(:end_conference)
    end

    it 'completes the call and leaves the hang-up to a job when Twilio cannot end the conference' do
      allow(conference).to receive(:end_conference).and_raise(Twilio::REST::TwilioError)

      expect { leave(agent_label) }.to have_enqueued_job(Voice::EndConferenceJob).with(call.id)
      expect(call.reload.status).to eq('completed')
    end
  end

  describe 'the contact leaving' do
    it 'completes the call and ends the conference, so no agent is left in it' do
      leave('contact')

      expect(call.reload.status).to eq('completed')
      expect(conference).not_to have_received(:agents_remain?)
      expect(conference).to have_received(:end_conference)
    end
  end

  describe 'the contact leaving after their status callback ended the call' do
    it 'ends the conference so the agent is not left on it' do
      call.update!(status: 'completed')

      leave('contact')

      expect(conference).to have_received(:end_conference)
      expect(call.reload.status).to eq('completed')
    end
  end

  describe 'the claiming agent leaving before their join callback arrives' do
    it 'ends the conference and completes the call' do
      call.update!(status: 'ringing')

      leave(agent_label)

      expect(call.reload.status).to eq('completed')
      expect(conference).to have_received(:end_conference)
    end
  end

  describe 'a claiming agent whose leg Twilio could not add' do
    def failed_add
      described_class.new(call: call, event: 'leave', participant_label: agent_label, participant_call_sid: 'CA-leaving',
                          leave_reason: 'participant_add_failed').process
    end

    it 'releases the claim on an inbound call, which rings on for the other agents' do
      call.update!(status: 'ringing')

      failed_add

      expect(call.reload).to have_attributes(status: 'ringing', accepted_by_agent_id: nil)
      expect(conference).not_to have_received(:end_conference)
    end

    it 'gives back a conversation the failed claim assigned, keeping an assignment made otherwise' do
      call.update!(status: 'ringing', ring_state: { 'assigned_by_claim' => agent.id })
      conversation.update!(assignee: agent)

      failed_add

      expect(conversation.reload.assignee).to be_nil
    end

    it 'gives the conversation to an agent who claimed the call before it was released' do
      other = create(:user, account: account, role: :agent)
      call.update!(status: 'ringing', ring_state: { 'assigned_by_claim' => agent.id })
      conversation.update!(assignee: agent)
      allow(conference).to receive(:remember_claim_assignment)
      manager = described_class.new(call: call, event: 'leave', participant_label: agent_label, participant_call_sid: 'CA-leaving',
                                    leave_reason: 'participant_add_failed')
      allow(manager).to receive(:release_failed_claim).and_wrap_original do |original, user_id|
        original.call(user_id).tap { Call.where(id: call.id).update_all(accepted_by_agent_id: other.id) } # rubocop:disable Rails/SkipsModelValidations
      end

      manager.process

      expect(conversation.reload.assignee).to eq(other)
      expect(conference).to have_received(:remember_claim_assignment).with(other.id)
    end

    it 'does not undo a later assignment when the same failure is reported again' do
      call.update!(status: 'ringing', ring_state: { 'assigned_by_claim' => agent.id })
      conversation.update!(assignee: agent)
      failed_add
      conversation.reload.update!(assignee: agent)

      # The repeated report arrives as a webhook of its own, with the call loaded afresh
      described_class.new(call: Call.find(call.id), event: 'leave', participant_label: agent_label, participant_call_sid: 'CA-leaving',
                          leave_reason: 'participant_add_failed').process

      expect(conversation.reload.assignee).to eq(agent)
    end

    it 'leaves the marker to a claim the same agent made again before the cleanup ran' do
      call.update!(status: 'ringing', ring_state: { 'assigned_by_claim' => agent.id })
      conversation.update!(assignee: agent)
      manager = described_class.new(call: call, event: 'leave', participant_label: agent_label, participant_call_sid: 'CA-leaving',
                                    leave_reason: 'participant_add_failed')

      # The agent's claim is released, then they claim the call again
      manager.send(:release_claim_assignment, agent.id)

      expect(call.reload.ring_state['assigned_by_claim']).to eq(agent.id)
      expect(conversation.reload.assignee).to eq(agent)
    end

    it 'keeps an assignment the claim did not make' do
      call.update!(status: 'ringing')
      conversation.update!(assignee: agent)

      failed_add

      expect(conversation.reload.assignee).to eq(agent)
    end

    it 'leaves hanging up the contact to a job when Twilio cannot do it at once' do
      call.update!(status: 'ringing', direction: :outgoing)
      allow(conference).to receive(:terminate_call).and_raise(Twilio::REST::TwilioError)

      expect { failed_add }.to have_enqueued_job(Voice::HangUpContactJob).with(call.id)
    end

    it 'records the call as failed, with its answer, when the contact had answered after all' do
      call.update!(status: 'ringing', direction: :outgoing, started_at: nil)
      failed_add
      ended_at = call.reload.ended_at.to_i
      answered_at = ended_at - 20
      conversation.update_columns(last_activity_at: 1.hour.ago) # rubocop:disable Rails/SkipsModelValidations

      Voice::CallStatus::Manager.new(call: Call.find(call.id)).process_status_update('in_progress', timestamp: answered_at)

      expect(call.reload).to have_attributes(status: 'failed', started_at: Time.zone.at(answered_at), duration_seconds: 20)
      # The correction reaches clients as any status change does
      expect(conversation.reload.last_activity_at).to be > 1.minute.ago
    end

    it 'ends an outbound call as unanswered, with its conference and the contact waiting in it' do
      call.update!(status: 'ringing', direction: :outgoing)

      failed_add

      expect(call.reload.status).to eq('no_answer')
      expect(conference).to have_received(:end_conference)
      expect(conference).to have_received(:terminate_call)
    end

    it 'leaves an outbound call alone when the agent has another connection on its way in' do
      call.update!(status: 'ringing', direction: :outgoing)
      with_legs('CA-leaving' => 'joining', 'CA-retry' => 'joining')

      failed_add

      expect(call.reload.status).to eq('ringing')
      expect(call.agent_legs.dig('CA-leaving', 'state')).to eq('gone')
      expect(conference).not_to have_received(:end_conference)
    end

    it 'keeps the claim and its assignment when a late failure arrives for a connection the agent replaced' do
      call.update!(status: 'in_progress', ring_state: { 'assigned_by_claim' => agent.id })
      with_legs('CA-retry' => 'joined')
      conversation.update!(assignee: agent)

      failed_add

      expect(call.reload).to have_attributes(status: 'in_progress', accepted_by_agent_id: agent.id)
      expect(conversation.reload.assignee).to eq(agent)
      expect(conference).not_to have_received(:end_conference)
    end

    it 'ends an outbound call the contact answered when the agent never got in' do
      call.update!(status: 'in_progress', direction: :outgoing)
      with_legs('CA-leaving' => 'joining')

      failed_add

      expect(call.reload.status).to eq('failed')
      expect(conference).to have_received(:end_conference)
    end

    it 'decides again once a connection still on its way in has had its time' do
      call.update!(status: 'ringing', direction: :outgoing)
      with_legs('CA-retry' => 'joining')

      expect { failed_add }.to have_enqueued_job(Voice::FailedAddRecheckJob).with(call.id, agent_label, 'CA-leaving')
      expect(call.reload.status).to eq('ringing')
    end

    it 'treats a connection that has not joined within its time as failed' do
      call.update!(status: 'ringing', direction: :outgoing)
      call.update!(meta: call.meta.merge('agent_legs' => { 'CA-retry' => { 'state' => 'joining', 'at' => 2.minutes.ago.to_i } }))

      failed_add

      expect(call.reload.status).to eq('no_answer')
    end
  end

  describe 'an agent joining' do
    it 'ignores a late join for a connection that has already left, keeping the place a newer join holds' do
      call.update!(status: 'ringing')
      with_legs('CA-old' => 'gone', Call.pending_agent_leg('attempt-2') => 'joining')

      described_class.new(call: call, event: 'join', participant_label: agent_label, participant_call_sid: 'CA-old').process

      expect(call.reload).to have_attributes(status: 'ringing')
      expect(call.agent_legs.dig(Call.pending_agent_leg('attempt-2'), 'state')).to eq('joining')
    end

    it 'keeps the place an accepted join holds, which may belong to a newer attempt' do
      call.update!(status: 'ringing')
      conversation.update!(assignee: agent)
      with_legs('CA-join' => 'joining', Call.pending_agent_leg('attempt-2') => 'joining')

      described_class.new(call: call, event: 'join', participant_label: agent_label, participant_call_sid: 'CA-join').process

      expect(call.reload.agent_legs.dig(Call.pending_agent_leg('attempt-2'), 'state')).to eq('joining')
    end

    it 'records their connection as on the call' do
      call.update!(status: 'ringing')
      conversation.update!(assignee: agent)
      with_legs('CA-join' => 'joining')

      described_class.new(call: call, event: 'join', participant_label: agent_label, participant_call_sid: 'CA-join').process

      expect(call.reload.agent_legs.dig('CA-join', 'state')).to eq('joined')
    end
  end

  describe 'an agent leaving while a new connection opens during the participant lookup' do
    it 'keeps the call for the new connection' do
      allow(conference).to receive(:agents_remain?) do
        Call.find(call.id).open_agent_leg!('CA-new')
        false
      end

      expect { leave(agent_label) }.to have_enqueued_job(Voice::EndConferenceJob)

      expect(call.reload.status).to eq('in_progress')
      expect(conference).not_to have_received(:end_conference)
    end
  end

  describe 'an agent leaving while a new connection joins during the participant lookup' do
    it 'keeps the call for the new connection' do
      allow(conference).to receive(:agents_remain?) do
        fresh = Call.find(call.id)
        fresh.open_agent_leg!('CA-new')
        fresh.with_lock { fresh.record_agent_leg!('CA-new', 'joined') }
        false
      end

      leave(agent_label)

      expect(call.reload.status).to eq('in_progress')
      expect(conference).not_to have_received(:end_conference)
    end
  end

  describe 'an agent whose join was accepted but whose connection has not asked for its instructions' do
    it 'keeps the call when the old connection leaves meanwhile' do
      call.update!(meta: call.meta.merge('agent_legs' => { Call.pending_agent_leg('attempt-2') => { 'state' => 'joining',
                                                                                                    'at' => Time.zone.now.to_i } }))

      leave(agent_label)

      expect(call.reload.status).to eq('in_progress')
      expect(conference).not_to have_received(:end_conference)
    end
  end

  describe 'an agent leaving while their new connection is on its way in' do
    it 'keeps the call and checks the conference again once the new connection has had its time' do
      with_legs('CA-leaving' => 'joined', 'CA-retry' => 'joining')

      expect { leave(agent_label) }.to have_enqueued_job(Voice::EndConferenceJob).with(call.id, leaving_call_sid: 'CA-leaving')

      expect(call.reload.status).to eq('in_progress')
      expect(conference).not_to have_received(:end_conference)
    end
  end

  describe 'an agent leg leaving while the call is still ringing' do
    it 'marks the call unanswered and leaves the conference to the other agents' do
      call.update!(status: 'in_progress')
      call.update!(status: 'ringing', accepted_by_agent: nil)

      leave(agent_label)

      expect(call.reload.status).to eq('no_answer')
      expect(conference).not_to have_received(:end_conference)
    end
  end
end
