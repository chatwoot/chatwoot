require 'rails_helper'

RSpec.describe 'Agent Bot messages API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:agent_bot) { create(:agent_bot) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }

  let!(:params) do
    {
      auth_token: agent_bot.auth_token,
      inbox_id: inbox.id,
      conversation_id: conversation.display_id,
      message: {
        type: 'text',
        content: 'Hello world'
      }
    }
  end

  describe 'POST /api/v1/agent_bot/messages' do
    it 'creates message from agent bot' do
      create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
      expect(conversation.messages.count).to eq 0

      post '/api/v1/agent_bot/messages',
           params: params
      expect(response).to have_http_status(:success)
      expect(conversation.messages.count).to eq 1
    end
  end
end
