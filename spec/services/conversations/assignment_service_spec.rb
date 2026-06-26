require 'rails_helper'

describe Conversations::AssignmentService do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account) }
  let(:agent_bot) { create(:agent_bot, account: account) }
  let(:conversation) { create(:conversation, account: account) }

  describe '#perform' do
    context 'when assignee_id is blank and inbox has an active bot' do
      before do
        inbox = conversation.inbox
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        conversation.update!(assignee: agent, assignee_agent_bot: nil)
      end

      it 'clears the human and assigns the inbox bot' do
        described_class.new(conversation: conversation, assignee_id: nil).perform

        conversation.reload
        expect(conversation.assignee_id).to be_nil
        expect(conversation.assignee_agent_bot_id).to eq(agent_bot.id)
      end
    end

    context 'when assignee_id is blank and inbox has no bot' do
      before do
        conversation.update!(assignee: agent, assignee_agent_bot: agent_bot)
      end

      it 'clears both human and bot assignees' do
        described_class.new(conversation: conversation, assignee_id: nil).perform

        conversation.reload
        expect(conversation.assignee_id).to be_nil
        expect(conversation.assignee_agent_bot_id).to be_nil
      end
    end

    context 'when assigning a user' do
      before do
        conversation.update!(assignee_agent_bot: agent_bot, assignee: nil)
      end

      it 'sets the agent and clears agent bot' do
        result = described_class.new(conversation: conversation, assignee_id: agent.id).perform

        conversation.reload
        expect(result).to eq(agent)
        expect(conversation.assignee_id).to eq(agent.id)
        expect(conversation.assignee_agent_bot_id).to be_nil
      end
    end

    context 'when assigning an agent bot' do
      let(:service) do
        described_class.new(
          conversation: conversation,
          assignee_id: agent_bot.id,
          assignee_type: 'AgentBot'
        )
      end

      before do
        create(:agent_bot_inbox, inbox: conversation.inbox, agent_bot: agent_bot)
      end

      it 'sets the agent bot and clears human assignee' do
        conversation.update!(assignee: agent, assignee_agent_bot: nil)

        result = service.perform

        conversation.reload
        expect(result).to eq(agent_bot)
        expect(conversation.assignee_agent_bot_id).to eq(agent_bot.id)
        expect(conversation.assignee_id).to be_nil
      end

      it 'does not assign an inactive inbox bot' do
        conversation.inbox.agent_bot_inbox.update!(status: :inactive)
        conversation.update!(assignee: agent, assignee_agent_bot: nil)

        result = service.perform

        conversation.reload
        expect(result).to be_nil
        expect(conversation.assignee_agent_bot_id).to be_nil
        expect(conversation.assignee_id).to eq(agent.id)
      end

      it 'does not assign a bot from another inbox' do
        other_bot = create(:agent_bot, account: account)
        other_service = described_class.new(
          conversation: conversation,
          assignee_id: other_bot.id,
          assignee_type: 'AgentBot'
        )

        result = other_service.perform

        conversation.reload
        expect(result).to be_nil
        expect(conversation.assignee_agent_bot_id).to be_nil
      end
    end
  end
end
