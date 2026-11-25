require 'rails_helper'

RSpec.describe 'Internal Chat Channels API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/:account_id/internal_chat/channels' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/internal_chat/channels"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      let!(:public_channel) { create(:internal_chat_channel, :public_channel, account: account, name: 'general') }
      let!(:private_channel) { create(:internal_chat_channel, :private_channel, account: account, name: 'secret') }

      it 'returns public channels visible to agent' do
        get "/api/v1/accounts/#{account.id}/internal_chat/channels",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        channel_names = body.map { |c| c['name'] }
        expect(channel_names).to include('general')
        expect(channel_names).not_to include('secret')
      end

      it 'returns private channels the agent is a member of' do
        create(:internal_chat_channel_member, channel: private_channel, user: agent)

        get "/api/v1/accounts/#{account.id}/internal_chat/channels",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        channel_names = body.map { |c| c['name'] }
        expect(channel_names).to include('general')
        expect(channel_names).to include('secret')
      end

      it 'filters by type text_channels' do
        create(:internal_chat_channel, :dm, account: account)

        get "/api/v1/accounts/#{account.id}/internal_chat/channels",
            params: { type: 'text_channels' },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body.map { |c| c['channel_type'] }).to all(satisfy { |t| t != 'dm' })
      end

      it 'filters by type direct_messages' do
        dm = create(:internal_chat_channel, :dm, account: account)
        create(:internal_chat_channel_member, channel: dm, user: agent)

        get "/api/v1/accounts/#{account.id}/internal_chat/channels",
            params: { type: 'direct_messages' },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body.map { |c| c['channel_type'] }).to all(eq('dm'))
      end

      it 'filters by status archived' do
        archived_channel = create(:internal_chat_channel, :public_channel, account: account, name: 'archived-ch', status: :archived)

        get "/api/v1/accounts/#{account.id}/internal_chat/channels",
            params: { status: 'archived' },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body.map { |c| c['id'] }).to include(archived_channel.id)
        expect(body.map { |c| c['id'] }).not_to include(public_channel.id)
      end

      it 'includes members_count, unread_count, and has_unread_mention in response' do
        get "/api/v1/accounts/#{account.id}/internal_chat/channels",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body.first).to have_key('members_count')
        expect(body.first).to have_key('unread_count')
        expect(body.first).to have_key('has_unread_mention')
      end

      it 'returns has_unread_mention true when an unread message mentions the user' do
        public_channel.channel_members.find_or_create_by!(user: agent).update!(last_read_at: 1.hour.ago)
        create(:internal_chat_message, account: account, channel: public_channel, sender: administrator,
                                       content_attributes: { 'mentioned_user_ids' => [agent.id] })

        get "/api/v1/accounts/#{account.id}/internal_chat/channels",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        mentioned_channel = body.find { |c| c['id'] == public_channel.id }
        expect(mentioned_channel['has_unread_mention']).to be(true)
      end

      it 'returns has_unread_mention true when an unread message mentions a team the user belongs to' do
        team = create(:team, account: account)
        create(:team_member, user: agent, team: team)
        public_channel.channel_members.find_or_create_by!(user: agent).update!(last_read_at: 1.hour.ago)
        # Simulate what message_create_service does: expand team mention to member IDs
        create(:internal_chat_message, account: account, channel: public_channel, sender: administrator,
                                       content_attributes: { 'mentioned_user_ids' => [agent.id] })

        get "/api/v1/accounts/#{account.id}/internal_chat/channels",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        mentioned_channel = body.find { |c| c['id'] == public_channel.id }
        expect(mentioned_channel['has_unread_mention']).to be(true)
      end

      it 'returns has_unread_mention false when no unread messages mention the user' do
        public_channel.channel_members.find_or_create_by!(user: agent).update!(last_read_at: 1.hour.ago)
        create(:internal_chat_message, account: account, channel: public_channel, sender: administrator,
                                       content: 'no mentions here')

        get "/api/v1/accounts/#{account.id}/internal_chat/channels",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        channel_data = body.find { |c| c['id'] == public_channel.id }
        expect(channel_data['has_unread_mention']).to be(false)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'returns all channels including private ones' do
        create(:internal_chat_channel, :public_channel, account: account, name: 'general')
        create(:internal_chat_channel, :private_channel, account: account, name: 'secret')

        get "/api/v1/accounts/#{account.id}/internal_chat/channels",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        channel_names = body.map { |c| c['name'] }
        expect(channel_names).to include('general')
        expect(channel_names).to include('secret')
      end

      it 'includes DMs the admin is a member of' do
        dm = create(:internal_chat_channel, :dm, account: account)
        create(:internal_chat_channel_member, channel: dm, user: administrator)

        get "/api/v1/accounts/#{account.id}/internal_chat/channels",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body.map { |c| c['id'] }).to include(dm.id)
      end

      it 'does not include DMs the admin is not a member of' do
        other_agent1 = create(:user, account: account, role: :agent)
        other_agent2 = create(:user, account: account, role: :agent)
        other_dm = create(:internal_chat_channel, :dm, account: account)
        create(:internal_chat_channel_member, channel: other_dm, user: other_agent1)
        create(:internal_chat_channel_member, channel: other_dm, user: other_agent2)

        create(:internal_chat_channel, :public_channel, account: account, name: 'visible-public')
        create(:internal_chat_channel, :private_channel, account: account, name: 'visible-private')

        get "/api/v1/accounts/#{account.id}/internal_chat/channels",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        channel_ids = body.map { |c| c['id'] }
        expect(channel_ids).not_to include(other_dm.id)
        channel_names = body.map { |c| c['name'] }
        expect(channel_names).to include('visible-public')
        expect(channel_names).to include('visible-private')
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/internal_chat/channels' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels",
             params: { channel: { name: 'test', channel_type: 'public_channel' } },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      it 'returns unauthorized for creating a public channel' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels",
             params: { channel: { name: 'test', channel_type: 'public_channel' } },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates a DM channel' do
        other_agent = create(:user, account: account, role: :agent)

        post "/api/v1/accounts/#{account.id}/internal_chat/channels",
             params: { channel: { channel_type: 'dm' }, member_ids: [other_agent.id] },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['channel_type']).to eq('dm')
        expect(body['members'].map { |m| m['user_id'] }).to include(agent.id, other_agent.id)
      end

      it 'returns existing DM if one already exists between the same users' do
        other_agent = create(:user, account: account, role: :agent)
        existing_dm = create(:internal_chat_channel, :dm, account: account, created_by: agent)
        create(:internal_chat_channel_member, channel: existing_dm, user: agent)
        create(:internal_chat_channel_member, channel: existing_dm, user: other_agent)

        post "/api/v1/accounts/#{account.id}/internal_chat/channels",
             params: { channel: { channel_type: 'dm' }, member_ids: [other_agent.id] },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['id']).to eq(existing_dm.id)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'creates a public channel' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels",
             params: { channel: { name: 'general', channel_type: 'public_channel', description: 'General chat' } },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['name']).to eq('general')
        expect(body['channel_type']).to eq('public_channel')
        expect(body['description']).to eq('General chat')
      end

      it 'creates a private channel' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels",
             params: { channel: { name: 'private-room', channel_type: 'private_channel' } },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['channel_type']).to eq('private_channel')
      end

      it 'returns payment_required when private channel limit is reached' do
        allow(InternalChat::Limits).to receive(:max_private_channels).and_return(2)
        create_list(:internal_chat_channel, 2, :private_channel, account: account)

        post "/api/v1/accounts/#{account.id}/internal_chat/channels",
             params: { channel: { name: 'third-private', channel_type: 'private_channel' } },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:payment_required)
        body = response.parsed_body
        expect(body['error']).to eq('pro_feature_required')
        expect(body['feature']).to eq('private_channels')
      end

      it 'does not count archived private channels toward the limit' do
        allow(InternalChat::Limits).to receive(:max_private_channels).and_return(2)
        create(:internal_chat_channel, :private_channel, account: account)
        create(:internal_chat_channel, :private_channel, :archived, account: account)

        post "/api/v1/accounts/#{account.id}/internal_chat/channels",
             params: { channel: { name: 'second-active-private', channel_type: 'private_channel' } },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
      end

      it 'adds the creator as admin member' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels",
             params: { channel: { name: 'new-channel', channel_type: 'public_channel' } },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        admin_member = body['members'].find { |m| m['user_id'] == administrator.id }
        expect(admin_member).to be_present
        expect(admin_member['role']).to eq('admin')
      end

      it 'creates a channel with initial members' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels",
             params: { channel: { name: 'team', channel_type: 'public_channel' }, member_ids: [agent.id] },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        member_user_ids = body['members'].map { |m| m['user_id'] }
        expect(member_user_ids).to include(agent.id)
      end

      it 'creates a channel with a category' do
        category = create(:internal_chat_category, account: account, name: 'Engineering')

        post "/api/v1/accounts/#{account.id}/internal_chat/channels",
             params: { channel: { name: 'backend', channel_type: 'public_channel', category_id: category.id } },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['category_id']).to eq(category.id)
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/internal_chat/channels/:id' do
    let!(:public_channel) { create(:internal_chat_channel, :public_channel, account: account, name: 'general') }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/internal_chat/channels/#{public_channel.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      it 'returns the public channel details' do
        get "/api/v1/accounts/#{account.id}/internal_chat/channels/#{public_channel.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['id']).to eq(public_channel.id)
        expect(body['name']).to eq('general')
        expect(body).to have_key('members')
        expect(body).to have_key('messages')
      end

      it 'returns unauthorized for a private channel the agent is not a member of' do
        private_channel = create(:internal_chat_channel, :private_channel, account: account, name: 'secret')

        get "/api/v1/accounts/#{account.id}/internal_chat/channels/#{private_channel.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns a private channel the agent is a member of' do
        private_channel = create(:internal_chat_channel, :private_channel, account: account, name: 'team-private')
        create(:internal_chat_channel_member, channel: private_channel, user: agent)

        get "/api/v1/accounts/#{account.id}/internal_chat/channels/#{private_channel.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['name']).to eq('team-private')
      end

      it 'includes recent messages in the response' do
        create(:internal_chat_message, account: account, channel: public_channel, sender: agent, content: 'Hello')

        get "/api/v1/accounts/#{account.id}/internal_chat/channels/#{public_channel.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['messages'].length).to eq(1)
        expect(body['messages'].first['content']).to eq('Hello')
      end
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/internal_chat/channels/:id' do
    let!(:channel) { create(:internal_chat_channel, :public_channel, account: account, name: 'old-name') }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}",
              params: { channel: { name: 'new-name' } }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent without admin role' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}",
              params: { channel: { name: 'new-name' } },
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is a channel admin (not account administrator)' do
      it 'updates the channel' do
        channel.channel_members.find_or_create_by!(user: agent).update!(role: :admin)

        patch "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}",
              params: { channel: { name: 'updated-name' } },
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['name']).to eq('updated-name')
      end
    end

    context 'when it is an authenticated administrator' do
      it 'updates the channel name and description' do
        patch "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}",
              params: { channel: { name: 'new-name', description: 'Updated desc' } },
              headers: administrator.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['name']).to eq('new-name')
        expect(body['description']).to eq('Updated desc')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/internal_chat/channels/:id' do
    let!(:channel) { create(:internal_chat_channel, :public_channel, account: account, name: 'to-delete') }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'destroys the channel' do
        delete "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(InternalChat::Channel.find_by(id: channel.id)).to be_nil
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/internal_chat/channels/:id/archive' do
    let!(:channel) { create(:internal_chat_channel, :public_channel, account: account, name: 'to-archive') }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/archive"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/archive",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'archives the channel' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/archive",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['status']).to eq('archived')
      end

      it 'rejects archiving a DM channel' do
        dm_channel = create(:internal_chat_channel, :dm, account: account)
        create(:internal_chat_channel_member, channel: dm_channel, user: administrator)

        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{dm_channel.id}/archive",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        dm_channel.reload
        expect(dm_channel.status).to eq('active')
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/internal_chat/channels/:id/unarchive' do
    let!(:channel) { create(:internal_chat_channel, :public_channel, account: account, name: 'archived-ch', status: :archived) }

    context 'when it is an authenticated administrator' do
      it 'unarchives the channel' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/unarchive",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['status']).to eq('active')
      end

      it 'returns payment_required when unarchiving a private channel would exceed the limit' do
        allow(InternalChat::Limits).to receive(:max_private_channels).and_return(2)
        create_list(:internal_chat_channel, 2, :private_channel, account: account)
        archived_private = create(:internal_chat_channel, :private_channel, :archived, account: account, name: 'old-private')

        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{archived_private.id}/unarchive",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:payment_required)
        body = response.parsed_body
        expect(body['error']).to eq('pro_feature_required')
        expect(body['feature']).to eq('private_channels')
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/internal_chat/channels/:id/mark_read' do
    let!(:channel) { create(:internal_chat_channel, :public_channel, account: account, name: 'general') }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/mark_read"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent who is a member' do
      before do
        channel.channel_members.find_or_create_by!(user: agent)
      end

      it 'marks the channel as read' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/mark_read",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        membership = channel.channel_members.find_by(user_id: agent.id)
        expect(membership.last_read_at).to be_present
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/internal_chat/channels/:id/mark_unread' do
    let!(:channel) { create(:internal_chat_channel, :public_channel, account: account, name: 'general') }

    context 'when it is an authenticated agent who is a member' do
      let!(:membership) { channel.channel_members.find_or_create_by!(user: agent).tap { |m| m.update!(last_read_at: Time.current) } }
      let!(:message) { create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'test') }

      it 'marks the channel as unread from a specific message' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/mark_unread",
             params: { message_id: message.id },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        membership.reload
        expect(membership.last_read_at).to be < message.created_at
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/internal_chat/channels/:id/toggle_typing_status' do
    let!(:channel) { create(:internal_chat_channel, :public_channel, account: account, name: 'general') }

    context 'when it is an authenticated agent' do
      it 'returns success' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/toggle_typing_status",
             params: { typing_status: 'on' },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end
end
