require 'rails_helper'

describe Conversations::InboundRoutingService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:message) { create(:message, conversation: conversation, account: account, message_type: :incoming) }

  def attach_captain
    create(:captain_inbox, inbox: inbox, captain_assistant: assistant)
  end

  describe '#perform' do
    context 'when the inbox has no captain assistant' do
      it 'routes to human and leaves the conversation open' do
        expect(described_class.new(message: message).perform).to eq(:human)
        expect(conversation.reload).to be_open
      end
    end

    context 'when the inbox is connected to a captain assistant' do
      it 'pends the conversation and schedules a captain response' do
        attach_captain
        scheduler = instance_double(Captain::Conversation::ResponseSchedulerService)
        allow(Captain::Conversation::ResponseSchedulerService).to receive(:new).with(message: message).and_return(scheduler)
        allow(scheduler).to receive(:perform)

        expect(described_class.new(message: message).perform).to eq(:captain)
        expect(conversation.reload).to be_pending
        expect(scheduler).to have_received(:perform)
      end

      context 'when an external bot is active' do
        before { attach_captain }

        it 'does not pend and hands the pending conversation to the human queue' do
          conversation.update!(status: :pending)
          allow(inbox).to receive(:external_bot_active?).and_return(true)
          allow(Captain::Conversation::ResponseSchedulerService).to receive(:new)

          expect(described_class.new(message: message).perform).to eq(:human)
          expect(conversation.reload).to be_open
          expect(Captain::Conversation::ResponseSchedulerService).not_to have_received(:new)
        end
      end

      context 'when an agent is already online and assigned' do
        it 'routes to human and leaves the conversation open' do
          agent = create(:user, account: account, role: :agent)
          conv = create(:conversation, account: account, inbox: inbox, assignee: agent, status: :open)
          msg = create(:message, conversation: conv, account: account, message_type: :incoming)
          attach_captain
          allow(OnlineStatusTracker).to receive(:get_available_users).and_return(agent.id => 'online')

          expect(described_class.new(message: msg).perform).to eq(:human)
          expect(conv.reload).to be_open
        end
      end
    end
  end
end
