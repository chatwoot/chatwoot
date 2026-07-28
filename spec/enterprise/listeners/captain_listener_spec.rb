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

  describe '#message_created' do
    let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :pending) }

    before do
      account.enable_features!('captain_integration_v2')
      create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
      create(
        :captain_conversation_outcome,
        account: account,
        assistant: assistant,
        conversation: conversation,
        inbox: inbox,
        eligible_at: 1.minute.ago
      )
    end

    it 'records public Captain replies' do
      message = create(
        :message,
        account: account,
        inbox: inbox,
        conversation: conversation,
        sender: assistant,
        message_type: :outgoing
      )
      event = Events::Base.new(:message_created, message.created_at, message: message)

      listener.message_created(event)

      expect(Captain::ConversationOutcome.last).to have_attributes(
        captain_involved_at: message.created_at,
        first_captain_reply_at: message.created_at
      )
    end

    it 'ignores Captain messages without an existing V2 outcome' do
      Captain::ConversationOutcome.delete_all
      message = create(
        :message,
        account: account,
        inbox: inbox,
        conversation: conversation,
        sender: assistant,
        message_type: :outgoing
      )
      event = Events::Base.new(:message_created, message.created_at, message: message)

      expect do
        listener.message_created(event)
      end.not_to change(Captain::ConversationOutcome, :count)
    end
  end
end
