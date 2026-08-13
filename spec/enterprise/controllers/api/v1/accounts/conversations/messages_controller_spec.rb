require 'rails_helper'

RSpec.describe 'Captain conversation messages API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, ai_assignee: assistant, status: :pending) }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
  end

  it 'blocks public replies while Captain owns the conversation' do
    post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
         params: { content: 'test-message' },
         headers: agent.create_new_auth_token,
         as: :json

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body['error']).to eq(I18n.t('errors.conversations.ai_assignee_reply_not_allowed'))
    expect(conversation.messages.count).to eq(0)
  end
end
