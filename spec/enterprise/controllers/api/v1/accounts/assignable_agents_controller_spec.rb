require 'rails_helper'

RSpec.describe 'Assignable Captain API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }

  before do
    create(:inbox_member, user: agent, inbox: inbox)
    create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
  end

  it 'returns the active connected Captain when requested' do
    get "/api/v1/accounts/#{account.id}/assignable_agents",
        params: { inbox_ids: [inbox.id], include_captain: true },
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

  it 'does not return a Captain connected to a different inbox' do
    other_inbox = create(:inbox, account: account)
    create(:inbox_member, user: agent, inbox: other_inbox)

    get "/api/v1/accounts/#{account.id}/assignable_agents",
        params: { inbox_ids: [other_inbox.id], include_captain: true },
        headers: agent.create_new_auth_token,
        as: :json

    expect(response.parsed_body['payload'].pluck('assignee_type')).not_to include('Captain::Assistant')
  end
end
