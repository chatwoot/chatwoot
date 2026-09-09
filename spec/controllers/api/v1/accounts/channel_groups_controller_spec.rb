require 'rails_helper'

RSpec.describe 'Channel Groups API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:channel_group) { create(:channel_group, account: account, name: 'Northstar') }
  let!(:inbox) { create(:inbox, account: account, channel_group: channel_group) }

  describe 'GET /api/v1/accounts/{account.id}/channel_groups' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/channel_groups"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      it 'lists only the members the agent can access' do
        accessible_inbox = create(:inbox, account: account, channel_group: channel_group)
        create(:inbox_member, user: agent, inbox: accessible_inbox)

        get "/api/v1/accounts/#{account.id}/channel_groups",
            headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(response).to conform_schema(200)
        expect(response.parsed_body.first['name']).to eq('Northstar')
        expect(response.parsed_body.first['inbox_ids']).to eq([accessible_inbox.id])
      end
    end

    context 'when it is an authenticated administrator' do
      it 'lists every member of the group' do
        get "/api/v1/accounts/#{account.id}/channel_groups",
            headers: administrator.create_new_auth_token, as: :json

        expect(response.parsed_body.first['inbox_ids']).to eq([inbox.id])
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/channel_groups' do
    let(:other_account_inbox) { create(:inbox, account: create(:account)) }

    it 'returns unauthorized for an agent' do
      post "/api/v1/accounts/#{account.id}/channel_groups",
           params: { channel_group: { name: 'Harbor' } },
           headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates the group with its members' do
      new_inbox = create(:inbox, account: account)

      post "/api/v1/accounts/#{account.id}/channel_groups",
           params: { channel_group: { name: 'Harbor', inbox_ids: [new_inbox.id] } },
           headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['name']).to eq('Harbor')
      expect(new_inbox.reload.channel_group_id).to eq(response.parsed_body['id'])
    end

    it 'ignores inboxes from another account' do
      post "/api/v1/accounts/#{account.id}/channel_groups",
           params: { channel_group: { name: 'Harbor', inbox_ids: [other_account_inbox.id] } },
           headers: administrator.create_new_auth_token, as: :json

      expect(response.parsed_body['inbox_ids']).to be_empty
      expect(other_account_inbox.reload.channel_group_id).to be_nil
    end

    it 'rejects a duplicate name' do
      post "/api/v1/accounts/#{account.id}/channel_groups",
           params: { channel_group: { name: 'northstar' } },
           headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/channel_groups/{id}' do
    it 'returns unauthorized for an agent' do
      patch "/api/v1/accounts/#{account.id}/channel_groups/#{channel_group.id}",
            params: { channel_group: { name: 'Renamed' } },
            headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'renames the group and keeps its members' do
      patch "/api/v1/accounts/#{account.id}/channel_groups/#{channel_group.id}",
            params: { channel_group: { name: 'Renamed' } },
            headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(channel_group.reload.name).to eq('Renamed')
      expect(response.parsed_body['inbox_ids']).to eq([inbox.id])
    end

    it 'replaces the members when inbox ids are sent' do
      new_inbox = create(:inbox, account: account)

      patch "/api/v1/accounts/#{account.id}/channel_groups/#{channel_group.id}",
            params: { channel_group: { name: 'Northstar', inbox_ids: [new_inbox.id] } },
            headers: administrator.create_new_auth_token, as: :json

      expect(response.parsed_body['inbox_ids']).to eq([new_inbox.id])
      expect(inbox.reload.channel_group_id).to be_nil
    end

    it 'moves an inbox out of the group it belonged to' do
      other_group = create(:channel_group, account: account, name: 'Harbor')

      patch "/api/v1/accounts/#{account.id}/channel_groups/#{other_group.id}",
            params: { channel_group: { name: 'Harbor', inbox_ids: [inbox.id] } },
            headers: administrator.create_new_auth_token, as: :json

      expect(inbox.reload.channel_group_id).to eq(other_group.id)
      expect(channel_group.reload.inboxes).to be_empty
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/channel_groups/{id}' do
    it 'returns unauthorized for an agent' do
      delete "/api/v1/accounts/#{account.id}/channel_groups/#{channel_group.id}",
             headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'deletes the group and keeps its inboxes' do
      delete "/api/v1/accounts/#{account.id}/channel_groups/#{channel_group.id}",
             headers: administrator.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(account.channel_groups).to be_empty
      expect(inbox.reload.channel_group_id).to be_nil
    end
  end
end
