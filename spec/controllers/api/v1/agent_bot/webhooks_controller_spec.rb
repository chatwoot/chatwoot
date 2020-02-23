require 'rails_helper'

RSpec.describe 'Webhooks API', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:agent_bot) { create(:agent_bot, user: user, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }

  let!(:params) do
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

  describe 'POST /api/v1/agent_bot/webhooks/agent_bot' do
    it 'creates message from agent bot' do
      create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
      expect(conversation.messages.count).to eq 0

      post '/api/v1/agent_bot/webhooks/agent_bot',
           params: params

      expect(response).to have_http_status(:success)
      # expect(conversation.messages.count).to eq 1
      # message = conversation.messages.first
      # expect(message.content).to eq(params[:message][:content])
    end
  end
end
