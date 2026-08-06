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
    let(:event) { Events::Base.new(event_name, Time.zone.now.change(usec: 0), conversation: conversation) }

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

    it 'records the resolution on an existing V2 outcome' do
      assistant.update!(config: {})
      outcome = create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        conversation: conversation,
        inbox: inbox
      )

      listener.conversation_resolved(event)

      expect(outcome.reload.resolved_at).to eq(event.timestamp)
    end
  end

  describe '#message_created' do
    let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :pending) }

    before do
      account.enable_features!('captain_integration_v2')
      create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        conversation: conversation,
        inbox: inbox,
        started_at: 1.hour.ago
      )
    end

    it 'records public Captain replies' do
      message = create(
        :message,
        account: account,
        inbox: inbox,
        conversation: conversation,
        sender: assistant,
        message_type: :outgoing,
        created_at: 5.minutes.ago.change(usec: 0)
      )
      event = Events::Base.new(:message_created, message.created_at, message: message)

      listener.message_created(event)

      expect(ConversationOutcome.last).to have_attributes(
        first_captain_reply_at: message.created_at,
        captain_reply_count: 1
      )
    end

    it 'ignores Captain messages without an existing V2 outcome' do
      ConversationOutcome.delete_all
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
      end.not_to change(ConversationOutcome, :count)
    end

    it 'records public human replies on the existing outcome' do
      message = create(
        :message,
        account: account,
        inbox: inbox,
        conversation: conversation,
        sender: user,
        message_type: :outgoing,
        created_at: 5.minutes.ago.change(usec: 0)
      )
      event = Events::Base.new(:message_created, message.created_at, message: message)

      listener.message_created(event)

      expect(ConversationOutcome.last.first_human_reply_at).to eq(message.created_at)
    end
  end

  describe '#message_updated' do
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }
    let!(:outcome) do
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        conversation: conversation,
        inbox: inbox
      )
    end

    it 'records a submitted CSAT response' do
      message = create(
        :message,
        account: account,
        inbox: inbox,
        conversation: conversation,
        content_type: :input_csat,
        message_type: :outgoing
      )
      response = create(
        :csat_survey_response,
        account: account,
        conversation: conversation,
        contact: conversation.contact,
        message: message,
        rating: 5
      )
      event = Events::Base.new(:message_updated, Time.current, message: message)

      listener.message_updated(event)

      expect(outcome.reload).to have_attributes(
        csat_rating: 5,
        csat_received_at: response.created_at
      )
    end
  end
end
