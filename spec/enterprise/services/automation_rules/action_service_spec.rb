require 'rails_helper'

RSpec.describe AutomationRules::ActionService do
  describe '#perform with assign_agent_bot action' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:bot) { create(:agent_bot, account: account, outgoing_url: 'https://bot.example.com/hook') }
    let!(:message) { create(:message, conversation: conversation, account: account, message_type: :incoming, content: 'I need help') }
    let(:rule) do
      create(:automation_rule, account: account, actions: [{ action_name: 'assign_agent_bot', action_params: [bot.id] }])
    end

    before { allow(AgentBots::WebhookJob).to receive(:perform_later) }

    it 'sends the message when the current ai assignee is a Captain assistant with the same id as the bot' do
      assistant = create(:captain_assistant, account: account, id: bot.id)
      conversation.update!(ai_assignee: assistant, assignee: nil)

      described_class.new(rule, account, conversation, message: message).perform

      expect(AgentBots::WebhookJob).to have_received(:perform_later).with(anything, hash_including(event: 'message_created'), any_args).once
    end
  end
end
