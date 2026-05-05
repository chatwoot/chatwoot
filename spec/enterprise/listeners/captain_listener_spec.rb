require 'rails_helper'

describe CaptainListener do
  let(:listener) { described_class.instance }
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:user) { create(:user, account: account) }
  let(:assistant) { create(:captain_assistant, account: account, config: { feature_memory: true, feature_faq: true }) }

  describe '#conversation_resolved' do
    let(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }

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
  end

  describe Captain::Llm::ContactNotesService do
    let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: create(:contact, account: account)) }
    let(:mock_chat) { instance_double(RubyLLM::Chat) }
    let(:mock_response) { instance_double(RubyLLM::Message, content: { notes: ['Customer prefers email follow ups'] }.to_json) }

    before do
      create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
      allow(RubyLLM).to receive(:chat).and_return(mock_chat)
      allow(mock_chat).to receive(:with_temperature).and_return(mock_chat)
      allow(mock_chat).to receive(:with_params).and_return(mock_chat)
      allow(mock_chat).to receive(:with_instructions).and_return(mock_chat)
      allow(mock_chat).to receive(:ask).and_return(mock_response)
    end

    it 'creates generated notes with captain source' do
      described_class.new(assistant, conversation).generate_and_update_notes

      created_note = conversation.contact.notes.last
      expect(created_note.source).to eq('captain')
      expect(created_note.metadata['agent_context']).to include(
        'origin' => 'captain_llm',
        'assistant_id' => assistant.id,
        'conversation_id' => conversation.id
      )
    end
  end
end
