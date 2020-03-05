require 'rails_helper'
describe AgentBotListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:agent_bot) { create(:agent_bot) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }
  let!(:message) do
    create(:message, message_type: 'outgoing',
                     account: account, inbox: inbox, conversation: conversation)
  end
  let!(:event) { Events::Base.new(event_name, Time.zone.now, message: message) }

  describe '#message_created' do
    let(:event_name) { :'conversation.created' }

    context 'when agent bot is not configured' do
      it 'does not send message to agent bot' do
        expect(AgentBotJob).to receive(:perform_later).exactly(0).times
        listener.message_created(event)
      end
    end

    context 'when agent bot is configured' do
      it 'sends message to agent bot' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        expect(AgentBotJob).to receive(:perform_later).with(agent_bot.outgoing_url, message.webhook_data.merge(event: 'message_created')).once
        listener.message_created(event)
      end
    end
  end
end
