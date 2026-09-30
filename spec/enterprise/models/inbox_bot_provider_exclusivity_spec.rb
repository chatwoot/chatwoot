require 'rails_helper'

RSpec.describe Inbox do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent_bot) { create(:agent_bot, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }

  context 'when an Agent Bot is connected' do
    let!(:connection) { create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot) }

    it 'rejects Captain and Dialogflow' do
      captain_connection = build(:captain_inbox, inbox: inbox, captain_assistant: assistant)
      dialogflow_hook = build(:integrations_hook, :dialogflow, inbox: inbox, account: account)

      expect(captain_connection).not_to be_valid
      expect(captain_connection.errors[:base]).to include('Disconnect Agent Bot before connecting Captain')
      expect(dialogflow_hook).not_to be_valid
      expect(dialogflow_hook.errors[:base]).to include('Disconnect Agent Bot before connecting Dialogflow')
    end

    it 'allows Captain after the Agent Bot is disabled' do
      connection.inactive!

      expect(build(:captain_inbox, inbox: inbox, captain_assistant: assistant)).to be_valid
    end
  end

  context 'when Captain is connected' do
    let!(:connection) { create(:captain_inbox, inbox: inbox, captain_assistant: assistant) }

    it 'rejects Agent Bot and Dialogflow' do
      agent_bot_connection = build(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
      dialogflow_hook = build(:integrations_hook, :dialogflow, inbox: inbox, account: account)

      expect(agent_bot_connection).not_to be_valid
      expect(agent_bot_connection.errors[:base]).to include('Disconnect Captain before connecting Agent Bot')
      expect(dialogflow_hook).not_to be_valid
      expect(dialogflow_hook.errors[:base]).to include('Disconnect Captain before connecting Dialogflow')
    end

    it 'allows Dialogflow after Captain is disconnected' do
      connection.destroy!

      expect(build(:integrations_hook, :dialogflow, inbox: inbox, account: account)).to be_valid
    end
  end

  context 'when Dialogflow is enabled' do
    let!(:hook) { create(:integrations_hook, :dialogflow, inbox: inbox, account: account) }

    it 'rejects Agent Bot and Captain' do
      agent_bot_connection = build(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
      captain_connection = build(:captain_inbox, inbox: inbox, captain_assistant: assistant)

      expect(agent_bot_connection).not_to be_valid
      expect(agent_bot_connection.errors[:base]).to include('Disconnect Dialogflow before connecting Agent Bot')
      expect(captain_connection).not_to be_valid
      expect(captain_connection.errors[:base]).to include('Disconnect Dialogflow before connecting Captain')
    end

    it 'allows Agent Bot after Dialogflow is disabled' do
      hook.disabled!

      expect(build(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)).to be_valid
    end
  end

  it 'rejects enabling an inactive Agent Bot while Captain is connected' do
    connection = create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot, status: :inactive)
    create(:captain_inbox, inbox: inbox, captain_assistant: assistant)

    expect { connection.active! }.to raise_error(ActiveRecord::RecordInvalid, /Disconnect Captain before connecting Agent Bot/)
  end

  it 'rejects enabling a disabled Dialogflow hook while Captain is connected' do
    hook = create(:integrations_hook, :dialogflow, inbox: inbox, account: account, status: :disabled)
    create(:captain_inbox, inbox: inbox, captain_assistant: assistant)

    expect { hook.enabled! }.to raise_error(ActiveRecord::RecordInvalid, /Disconnect Captain before connecting Dialogflow/)
  end

  it 'allows manual Agent Bot assignment on a Captain-connected inbox' do
    create(:captain_inbox, inbox: inbox, captain_assistant: assistant)
    conversation = create(:conversation, account: account, inbox: inbox).reload

    Conversations::AssignmentService.new(conversation: conversation, assignee_id: agent_bot.id, assignee_type: 'AgentBot').perform

    expect(conversation.reload.ai_assignee).to eq(agent_bot)
  end
end
