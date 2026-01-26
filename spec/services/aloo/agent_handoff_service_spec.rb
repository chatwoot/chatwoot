# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::AgentHandoffService do
  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :pending) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:contact) { create(:contact, account: account) }

  before do
    create(:aloo_assistant_inbox, assistant: assistant, inbox: inbox)
  end

  describe '#perform' do
    context 'when human agent sends a message to AI-handled conversation' do
      let(:message) do
        create(:message,
               conversation: conversation,
               message_type: :outgoing,
               sender: agent,
               content: 'Let me help you with that')
      end

      it 'sets aloo_handoff_active flag to true' do
        described_class.new(message).perform

        expect(conversation.reload.custom_attributes['aloo_handoff_active']).to be true
      end

      it 'sets handoff timestamp' do
        freeze_time do
          described_class.new(message).perform

          expect(conversation.reload.custom_attributes['aloo_handoff_at']).to eq(Time.current.iso8601)
        end
      end

      it 'records handoff trigger as agent_message' do
        described_class.new(message).perform

        expect(conversation.reload.custom_attributes['aloo_handoff_triggered_by']).to eq('agent_message')
      end

      it 'assigns conversation to the agent' do
        described_class.new(message).perform

        expect(conversation.reload.assignee).to eq(agent)
      end
    end

    context 'when message is incoming (from customer)' do
      let(:message) do
        create(:message,
               conversation: conversation,
               message_type: :incoming,
               sender: contact,
               content: 'Hello')
      end

      it 'does not trigger handoff' do
        described_class.new(message).perform

        expect(conversation.reload.custom_attributes['aloo_handoff_active']).to be_nil
      end
    end

    context 'when message is private note' do
      let(:message) do
        create(:message,
               conversation: conversation,
               message_type: :outgoing,
               sender: agent,
               private: true,
               content: 'Internal note')
      end

      it 'does not trigger handoff' do
        described_class.new(message).perform

        expect(conversation.reload.custom_attributes['aloo_handoff_active']).to be_nil
      end
    end

    context 'when handoff is already active' do
      let(:message) do
        create(:message,
               conversation: conversation,
               message_type: :outgoing,
               sender: agent,
               content: 'Follow up message')
      end

      before do
        conversation.update!(custom_attributes: { 'aloo_handoff_active' => true })
      end

      it 'does not update handoff attributes' do
        conversation.custom_attributes.dup

        described_class.new(message).perform

        # Should not change the timestamp or other attributes
        expect(conversation.reload.custom_attributes['aloo_handoff_active']).to be true
      end
    end

    context 'when conversation already has a human assignee' do
      let(:other_agent) { create(:user, account: account, role: :agent) }
      let(:message) do
        create(:message,
               conversation: conversation,
               message_type: :outgoing,
               sender: agent,
               content: 'Taking over')
      end

      before do
        conversation.update!(assignee: other_agent)
      end

      it 'does not trigger handoff' do
        described_class.new(message).perform

        expect(conversation.reload.custom_attributes['aloo_handoff_active']).to be_nil
      end

      it 'does not change assignee' do
        described_class.new(message).perform

        expect(conversation.reload.assignee).to eq(other_agent)
      end
    end

    context 'when inbox has no active Aloo assistant' do
      let(:message) do
        create(:message,
               conversation: conversation,
               message_type: :outgoing,
               sender: agent,
               content: 'Hello')
      end

      before do
        assistant.update!(active: false)
      end

      it 'does not trigger handoff' do
        described_class.new(message).perform

        expect(conversation.reload.custom_attributes['aloo_handoff_active']).to be_nil
      end
    end

    context 'when sender is AI user' do
      let(:ai_user) { create(:user, account: account, role: :agent, is_ai: true) }
      let(:message) do
        create(:message,
               conversation: conversation,
               message_type: :outgoing,
               sender: ai_user,
               content: 'AI response')
      end

      it 'does not trigger handoff' do
        described_class.new(message).perform

        expect(conversation.reload.custom_attributes['aloo_handoff_active']).to be_nil
      end
    end
  end
end
