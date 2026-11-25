require 'rails_helper'

RSpec.describe Captain::ReportingEventListener do
  let(:listener) { described_class.instance }
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:assistant) { create(:captain_assistant, account: account) }

  describe '#captain_conversation_resolved' do
    it 'creates a captain inference resolved reporting event for inference resolutions' do
      decision_time = conversation.created_at + 60.seconds
      event = Events::Base.new(
        Events::Types::CAPTAIN_CONVERSATION_RESOLVED, decision_time,
        conversation: conversation, assistant: assistant, source: 'inference'
      )

      listener.captain_conversation_resolved(event)

      reporting_event = account.reporting_events.where(name: 'conversation_captain_inference_resolved').first
      expect(reporting_event).to be_present
      expect(reporting_event.value).to eq 60
      expect(reporting_event.event_end_time).to be_within(1.second).of(decision_time)
    end
  end

  describe '#captain_conversation_handed_off' do
    it 'creates a captain inference handoff reporting event for inference handoffs' do
      decision_time = conversation.created_at + 90.seconds
      event = Events::Base.new(
        Events::Types::CAPTAIN_CONVERSATION_HANDED_OFF, decision_time,
        conversation: conversation, assistant: assistant, source: 'inference', reason_category: :pending_clarification
      )

      listener.captain_conversation_handed_off(event)

      reporting_event = account.reporting_events.where(name: 'conversation_captain_inference_handoff').first
      expect(reporting_event).to be_present
      expect(reporting_event.value).to eq 90
      expect(reporting_event.event_end_time).to be_within(1.second).of(decision_time)
    end

    it 'does not create a reporting event for non-inference handoffs' do
      event = Events::Base.new(
        Events::Types::CAPTAIN_CONVERSATION_HANDED_OFF, Time.zone.now,
        conversation: conversation, assistant: assistant, source: 'tool', reason_category: nil
      )

      expect { listener.captain_conversation_handed_off(event) }
        .not_to(change { account.reporting_events.count })
    end
  end
end
