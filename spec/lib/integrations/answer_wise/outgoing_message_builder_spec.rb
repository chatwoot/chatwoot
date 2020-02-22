require 'rails_helper'

describe Integrations::AnswerWise::OutgoingMessageBuilder do
  subject(:message_builder) { described_class.new(options).perform }

  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:agent_bot) { create(:agent_bot, user: user, account: account) }
  let(:agent_bot_inbox) { create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }

  let!(:options) do
    {
      agent_bot_id: agent_bot.id,
      inbox_id: inbox.id,
      conversation_id: conversation.id,
      message: {
        type: 'text',
        content: 'Hello world'
      }
    }
  end

  describe '#perform' do
    it 'creates message from agent bot' do
      expect(conversation.messages.count).to eq 0
      message_builder

      expect(conversation.messages.count).to eq 1
      message = conversation.messages.first
      expect(message.content).to eq(options[:message][:content])
    end
  end
end
