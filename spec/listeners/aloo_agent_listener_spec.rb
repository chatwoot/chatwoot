# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AlooAgentListener do
  let(:listener) { described_class.instance }
  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, :with_all_features, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  before do
    create(:aloo_assistant_inbox, assistant: assistant, inbox: inbox)
  end

  describe '#message_created' do
    let(:message) { create(:message, conversation: conversation, message_type: :incoming, content: 'Hello') }
    let(:event) { Events::Base.new('message.created', Time.zone.now, message: message) }

    context 'when assistant is configured' do
      it 'enqueues ResponseJob for incoming messages' do
        expect(Aloo::ResponseJob).to receive(:perform_later)
          .with(conversation.id, message.id)

        listener.message_created(event)
      end
    end

    context 'when message is outgoing' do
      let(:message) { create(:message, conversation: conversation, message_type: :outgoing) }

      it 'does not enqueue job' do
        expect(Aloo::ResponseJob).not_to receive(:perform_later)

        listener.message_created(event)
      end
    end

    context 'when message is private' do
      let(:message) { create(:message, conversation: conversation, message_type: :incoming, private: true) }

      it 'does not enqueue job' do
        expect(Aloo::ResponseJob).not_to receive(:perform_later)

        listener.message_created(event)
      end
    end

    context 'when message has no content' do
      let(:message) { create(:message, conversation: conversation, message_type: :incoming, content: nil) }

      it 'does not enqueue job' do
        expect(Aloo::ResponseJob).not_to receive(:perform_later)

        listener.message_created(event)
      end
    end

    context 'when assistant is inactive' do
      before { assistant.update!(active: false) }

      it 'does not enqueue job' do
        expect(Aloo::ResponseJob).not_to receive(:perform_later)

        listener.message_created(event)
      end
    end

    context 'when human_assistance_requested but no human assignee' do
      before do
        conversation.update!(custom_attributes: { 'human_assistance_requested' => true })
      end

      it 'still enqueues job (AI keeps responding until human assigned)' do
        expect(Aloo::ResponseJob).to receive(:perform_later)
          .with(conversation.id, message.id)

        listener.message_created(event)
      end
    end

    context 'when human assignee present' do
      let(:agent) { create(:user, account: account) }

      before do
        conversation.update!(assignee: agent)
      end

      it 'does not enqueue job' do
        expect(Aloo::ResponseJob).not_to receive(:perform_later)

        listener.message_created(event)
      end
    end

    context 'when no assistant configured' do
      before do
        Aloo::AssistantInbox.where(inbox: inbox).destroy_all
      end

      it 'does not enqueue job' do
        expect(Aloo::ResponseJob).not_to receive(:perform_later)

        listener.message_created(event)
      end
    end
  end

  describe '#conversation_resolved' do
    let(:event) do
      Events::Base.new('conversation.resolved', Time.zone.now, conversation: conversation)
    end

    context 'when FAQ feature enabled' do
      it 'enqueues FaqGeneratorJob' do
        expect(Aloo::FaqGeneratorJob).to receive(:perform_later)
          .with(conversation.id)

        listener.conversation_resolved(event)
      end
    end

    context 'when FAQ feature disabled' do
      before { assistant.update!(admin_config: { 'feature_faq' => false }) }

      it 'does not enqueue FaqGeneratorJob' do
        expect(Aloo::FaqGeneratorJob).not_to receive(:perform_later)

        listener.conversation_resolved(event)
      end
    end

    context 'when assistant inactive' do
      before { assistant.update!(active: false) }

      it 'does not enqueue jobs' do
        expect(Aloo::FaqGeneratorJob).not_to receive(:perform_later)

        listener.conversation_resolved(event)
      end
    end

    context 'when no assistant configured' do
      before do
        Aloo::AssistantInbox.where(inbox: inbox).destroy_all
      end

      it 'does not enqueue jobs' do
        expect(Aloo::FaqGeneratorJob).not_to receive(:perform_later)

        listener.conversation_resolved(event)
      end
    end
  end

  describe '#conversation_status_changed' do
    context 'when reopened from resolved' do
      let(:agent) { create(:user, account: account) }

      before do
        conversation.update!(assignee: agent, custom_attributes: { 'human_assistance_requested' => true })
      end

      it 'clears assignee' do
        event = Events::Base.new(
          'conversation.status_changed',
          Time.zone.now,
          conversation: conversation,
          changed_attributes: { 'status' => %w[resolved open] }
        )

        listener.conversation_status_changed(event)

        expect(conversation.reload.assignee).to be_nil
      end

      it 'clears human_assistance_requested' do
        event = Events::Base.new(
          'conversation.status_changed',
          Time.zone.now,
          conversation: conversation,
          changed_attributes: { 'status' => %w[resolved open] }
        )

        listener.conversation_status_changed(event)

        expect(conversation.reload.custom_attributes['human_assistance_requested']).to be false
      end
    end

    context 'when no handoff flag' do
      it 'does nothing' do
        event = Events::Base.new(
          'conversation.status_changed',
          Time.zone.now,
          conversation: conversation,
          changed_attributes: { 'status' => %w[pending open] }
        )

        expect { listener.conversation_status_changed(event) }.not_to(change do
          conversation.reload.custom_attributes
        end)
      end
    end

    context 'when status not changed to open' do
      let(:agent) { create(:user, account: account) }

      before do
        conversation.update!(assignee: agent)
      end

      it 'does not clear assignee' do
        event = Events::Base.new(
          'conversation.status_changed',
          Time.zone.now,
          conversation: conversation,
          changed_attributes: { 'status' => %w[open resolved] }
        )

        listener.conversation_status_changed(event)

        expect(conversation.reload.assignee).to eq(agent)
      end
    end

    context 'when no status change' do
      it 'does nothing' do
        event = Events::Base.new(
          'conversation.status_changed',
          Time.zone.now,
          conversation: conversation,
          changed_attributes: { 'priority' => %w[medium high] }
        )

        expect { listener.conversation_status_changed(event) }.not_to raise_error
      end
    end
  end
end
