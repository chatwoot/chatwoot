require 'rails_helper'

describe CaptainListener do
  let(:listener) { described_class.instance }
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:user) { create(:user, account: account) }
  let(:assistant) { create(:captain_assistant, account: account, config: { feature_memory: true, feature_faq: true }) }

  describe '#conversation_resolved' do
    let(:agent) { create(:user, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }

    let(:event_name) { :conversation_resolved }
    let(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation) }

    before do
      create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
    end

    context 'when feature_memory is enabled' do
      before do
        assistant.config['feature_memory'] = true
        assistant.config['feature_faq'] = false
        assistant.save!
      end

      it 'generates and updates notes' do
        expect(Captain::Llm::ContactNotesService)
          .to receive(:new)
          .with(assistant, conversation)
          .and_return(instance_double(Captain::Llm::ContactNotesService, generate_and_update_notes: nil))
        expect(Captain::Llm::ConversationFaqService).not_to receive(:new)

        listener.conversation_resolved(event)
      end
    end

    context 'when feature_faq is enabled' do
      before do
        assistant.config['feature_faq'] = true
        assistant.config['feature_memory'] = false
        assistant.save!
      end

      it 'generates and deduplicates FAQs' do
        expect(Captain::Llm::ConversationFaqService)
          .to receive(:new)
          .with(assistant, conversation)
          .and_return(instance_double(Captain::Llm::ConversationFaqService, generate_and_deduplicate: false))
        expect(Captain::Llm::ContactNotesService).not_to receive(:new)

        listener.conversation_resolved(event)
      end
    end

    context 'when resolved by Captain scheduler' do
      let(:event) do
        Events::Base.new(
          event_name,
          Time.zone.now,
          conversation: conversation,
          performed_by: assistant,
          captain_action_source: 'scheduler'
        )
      end

      before do
        assistant.update!(config: { 'feature_memory' => false, 'feature_faq' => false })
      end

      it 'creates a captain_conversation_resolved reporting event with scheduler source' do
        listener.conversation_resolved(event)

        reporting_event = ReportingEvent.find_by(conversation_id: conversation.id, name: 'captain_conversation_resolved')
        expect(reporting_event).to be_present
        expect(reporting_event.source).to eq('scheduler')
      end
    end

    context 'when resolved by a human agent' do
      let(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, performed_by: agent) }

      before do
        assistant.update!(config: { 'feature_memory' => false, 'feature_faq' => false })
      end

      it 'does not create a captain reporting event' do
        listener.conversation_resolved(event)

        expect(ReportingEvent.find_by(conversation_id: conversation.id, name: 'captain_conversation_resolved')).to be_nil
      end
    end

    context 'when resolved by Captain assistant outside scheduler flow' do
      let(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, performed_by: assistant) }

      before do
        assistant.update!(config: { 'feature_memory' => false, 'feature_faq' => false })
      end

      it 'creates a captain reporting event with assistant source' do
        listener.conversation_resolved(event)

        reporting_event = ReportingEvent.find_by(conversation_id: conversation.id, name: 'captain_conversation_resolved')
        expect(reporting_event).to be_present
        expect(reporting_event.source).to eq('assistant')
      end
    end
  end

  describe '#conversation_bot_handoff' do
    let(:agent) { create(:user, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }
    let(:event_name) { :conversation_bot_handoff }

    before do
      create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
    end

    context 'when handoff is performed by Captain scheduler' do
      let(:event) do
        Events::Base.new(
          event_name,
          Time.zone.now,
          conversation: conversation,
          performed_by: assistant,
          captain_action_source: 'scheduler'
        )
      end

      it 'creates a captain_conversation_handoff reporting event with scheduler source' do
        listener.conversation_bot_handoff(event)

        reporting_event = ReportingEvent.find_by(conversation_id: conversation.id, name: 'captain_conversation_handoff')
        expect(reporting_event).to be_present
        expect(reporting_event.source).to eq('scheduler')
      end
    end

    context 'when handoff is not performed by Captain assistant' do
      let(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, performed_by: agent) }

      it 'does not create a captain reporting event' do
        listener.conversation_bot_handoff(event)

        expect(ReportingEvent.find_by(conversation_id: conversation.id, name: 'captain_conversation_handoff')).to be_nil
      end
    end

    context 'when handoff is performed by Captain assistant outside scheduler flow' do
      let(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, performed_by: assistant) }

      it 'creates a captain reporting event with assistant source' do
        listener.conversation_bot_handoff(event)

        reporting_event = ReportingEvent.find_by(conversation_id: conversation.id, name: 'captain_conversation_handoff')
        expect(reporting_event).to be_present
        expect(reporting_event.source).to eq('assistant')
      end
    end
  end
end
