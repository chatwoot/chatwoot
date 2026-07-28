require 'rails_helper'

RSpec.describe ReportingEventListener do
  let(:listener) { described_class.instance }
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:decision_time) { Time.zone.now }

  describe '#captain_conversation_resolved' do
    it 'creates a captain inference resolved reporting event for inference resolutions' do
      event = Events::Base.new(
        Events::Types::CAPTAIN_CONVERSATION_RESOLVED, decision_time,
        conversation: conversation, assistant: assistant, source: 'inference'
      )

      expect { listener.captain_conversation_resolved(event) }
        .to change { account.reporting_events.where(name: 'conversation_captain_inference_resolved').count }.by(1)
    end
  end

  describe '#captain_conversation_handed_off' do
    it 'creates a captain inference handoff reporting event for inference handoffs' do
      event = Events::Base.new(
        Events::Types::CAPTAIN_CONVERSATION_HANDED_OFF, decision_time,
        conversation: conversation, assistant: assistant, source: 'inference', reason_category: :pending_clarification
      )

      expect { listener.captain_conversation_handed_off(event) }
        .to change { account.reporting_events.where(name: 'conversation_captain_inference_handoff').count }.by(1)
    end

    it 'does not create a reporting event for non-inference handoffs' do
      event = Events::Base.new(
        Events::Types::CAPTAIN_CONVERSATION_HANDED_OFF, decision_time,
        conversation: conversation, assistant: assistant, source: 'tool', reason_category: nil
      )

      expect { listener.captain_conversation_handed_off(event) }
        .not_to(change { account.reporting_events.count })
    end
  end
end
