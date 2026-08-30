require 'rails_helper'

RSpec.describe 'Assignable Captain API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:assignment_enabled) { true }

  before do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load)
      .with('ENABLE_CAPTAIN_CONVERSATION_ASSIGNMENT', false)
      .and_return(assignment_enabled)
    create(:inbox_member, user: agent, inbox: inbox)
    create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
  end

  it 'returns the active connected Captain when requested' do
    get "/api/v1/accounts/#{account.id}/assignable_agents",
        params: { inbox_ids: [inbox.id], include_ai_assignees: true },
        headers: agent.create_new_auth_token,
        as: :json

    captain = response.parsed_body['payload'].find { |owner| owner['assignee_type'] == 'Captain::Assistant' }

    expect(captain).to include('id' => assistant.id, 'name' => assistant.name)
  end

  it 'does not return Captain without the opt-in' do
    get "/api/v1/accounts/#{account.id}/assignable_agents",
        params: { inbox_ids: [inbox.id] },
        headers: agent.create_new_auth_token,
        as: :json

    expect(response.parsed_body['payload'].pluck('assignee_type')).not_to include('Captain::Assistant')
  end

  context 'when Captain conversation assignment is disabled' do
    let(:assignment_enabled) { false }

    it 'does not return Captain' do
      get "/api/v1/accounts/#{account.id}/assignable_agents",
          params: { inbox_ids: [inbox.id], include_ai_assignees: true },
          headers: agent.create_new_auth_token,
          as: :json

      expect(response.parsed_body['payload'].pluck('assignee_type')).not_to include('Captain::Assistant')
    end
  end

  it 'does not return Captain when an external bot is active' do
    create(:agent_bot_inbox, inbox: inbox, agent_bot: create(:agent_bot, account: account))

    get "/api/v1/accounts/#{account.id}/assignable_agents",
        params: { inbox_ids: [inbox.id], include_ai_assignees: true },
        headers: agent.create_new_auth_token,
        as: :json

    expect(response.parsed_body['payload'].pluck('assignee_type')).not_to include('Captain::Assistant')
  end

  it 'does not return a Captain connected to a different inbox' do
    other_inbox = create(:inbox, account: account)
    create(:inbox_member, user: agent, inbox: other_inbox)

    get "/api/v1/accounts/#{account.id}/assignable_agents",
        params: { inbox_ids: [other_inbox.id], include_ai_assignees: true },
        headers: agent.create_new_auth_token,
        as: :json

    expect(response.parsed_body['payload'].pluck('assignee_type')).not_to include('Captain::Assistant')
  end
end
