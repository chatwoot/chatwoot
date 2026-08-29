require 'rails_helper'

RSpec.describe 'Captain assistant conversation assignment API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:assignment_enabled) { true }

  before do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load)
      .with('ENABLE_CAPTAIN_CONVERSATION_ASSIGNMENT', false)
      .and_return(assignment_enabled)
    create(:inbox_member, inbox: inbox, user: agent)
    conversation
    create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
  end

  it 'assigns the connected Captain assistant and marks the conversation pending' do
    conversation.update!(assignee: agent, status: :open)

    post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
         params: { assignee_id: assistant.id, assignee_type: 'Captain::Assistant' },
         headers: agent.create_new_auth_token,
         as: :json

    expect(response).to have_http_status(:success)
    expect(response.parsed_body).to include('id' => assistant.id, 'name' => assistant.name)
    expect(conversation.reload).to have_attributes(
      ai_assignee: assistant,
      ai_assignee_type: 'Captain::Assistant',
      assignee: nil,
      status: 'pending'
    )

    get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
        headers: agent.create_new_auth_token,
        as: :json

    expect(response.parsed_body.dig('meta', 'assignee')).to include('id' => assistant.id, 'name' => assistant.name)
    expect(response.parsed_body.dig('meta', 'assignee_type')).to eq('Captain::Assistant')
  end

  context 'when Captain conversation assignment is disabled' do
    let(:assignment_enabled) { false }

    it 'does not assign the Captain assistant' do
      post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
           params: { assignee_id: assistant.id, assignee_type: 'Captain::Assistant' },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to be_nil
      expect(conversation.reload.ai_assignee).to be_nil
    end
  end

  it 'does not assign an unconnected Captain assistant' do
    unconnected_assistant = create(:captain_assistant, account: account)

    post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
         params: { assignee_id: unconnected_assistant.id, assignee_type: 'Captain::Assistant' },
         headers: agent.create_new_auth_token,
         as: :json

    expect(response).to have_http_status(:success)
    expect(response.parsed_body).to be_nil
    expect(conversation.reload.ai_assignee).to be_nil
  end

  it 'clears Captain assistant ownership when a human takes over' do
    conversation.update!(ai_assignee: assistant, status: :pending)

    post api_v1_account_conversation_assignments_url(account_id: account.id, conversation_id: conversation.display_id),
         params: { assignee_id: agent.id },
         headers: agent.create_new_auth_token,
         as: :json

    expect(response).to have_http_status(:success)
    expect(conversation.reload).to have_attributes(
      ai_assignee: nil,
      ai_assignee_type: nil,
      assignee: agent,
      status: 'open'
    )
  end
end
