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
        expect(Captain::Llm::ConversationFaqJob).not_to receive(:perform_later)

        listener.conversation_resolved(event)
      end
    end

    context 'when feature_faq is enabled' do
      before do
        assistant.config['feature_faq'] = true
        assistant.config['feature_memory'] = false
        assistant.save!
      end

      it 'enqueues FAQ suggestion generation' do
        expect(Captain::Llm::ConversationFaqJob).to receive(:perform_later).with(conversation, assistant)
        expect(Captain::Llm::ContactNotesService).not_to receive(:new)

        listener.conversation_resolved(event)
      end
    end
  end

  describe '#conversation_language_detected' do
    let(:contact) { create(:contact, account: account) }
    let(:conversation) do
      create(:conversation, account: account, inbox: inbox, contact: contact, status: :pending)
    end
    let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming) }
    let(:event) do
      conversation.update!(additional_attributes: conversation.additional_attributes.merge('conversation_language' => detected_language))
      Events::Base.new(:conversation_language_detected, Time.zone.now, conversation: conversation, message: message)
    end
    let(:detected_language) { 'en' }

    before do
      create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
      create(:integrations_hook, :google_translate, account: account)
      assistant.update!(config: assistant.config.merge('audience' => {
                                                         'attribute_key' => 'conversation_language', 'filter_operator' => 'equal_to',
                                                         'values' => ['en']
                                                       }))
    end

    it 'schedules Captain when the detected language matches' do
      scheduler = instance_double(Captain::Conversation::ResponseSchedulerService, perform: true)
      expect(Captain::Conversation::ResponseSchedulerService).to receive(:new).with(message: message).and_return(scheduler)

      listener.conversation_language_detected(event)

      expect(scheduler).to have_received(:perform)
      expect(conversation.reload).to be_pending
      expect(conversation.additional_attributes).not_to have_key(Captain::Assistant::LANGUAGE_ELIGIBILITY_PENDING_KEY)
    end

    context 'when the detected language does not match' do
      let(:detected_language) { 'fr' }

      it 'routes the conversation to humans' do
        expect(Captain::Conversation::ResponseSchedulerService).not_to receive(:new)

        listener.conversation_language_detected(event)

        expect(conversation.reload).to be_open
        expect(conversation.additional_attributes).not_to have_key(Captain::Assistant::LANGUAGE_ELIGIBILITY_PENDING_KEY)
      end
    end
  end
end
