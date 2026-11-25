require 'rails_helper'

RSpec.describe 'Internal Chat Messages API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:channel) { create(:internal_chat_channel, :public_channel, account: account, name: 'general') }

  describe 'GET /api/v1/accounts/:account_id/internal_chat/channels/:channel_id/messages' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      it 'returns messages for a public channel' do
        create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'Hello world')

        get "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['messages'].length).to eq(1)
        expect(body['messages'].first['content']).to eq('Hello world')
      end

      it 'returns messages with pagination meta' do
        get "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body).to have_key('meta')
        expect(body['meta']).to have_key('has_more')
      end

      it 'returns unauthorized for a private channel the agent is not a member of' do
        private_channel = create(:internal_chat_channel, :private_channel, account: account, name: 'secret')

        get "/api/v1/accounts/#{account.id}/internal_chat/channels/#{private_channel.id}/messages",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'filters messages with before parameter' do
        old_message = create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'old',
                                                     created_at: 2.hours.ago)
        new_message = create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'new',
                                                     created_at: 1.minute.ago)

        get "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages",
            params: { before: new_message.created_at.iso8601 },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        message_ids = body['messages'].map { |m| m['id'] }
        expect(message_ids).to include(old_message.id)
        expect(message_ids).not_to include(new_message.id)
      end

      it 'filters messages with after parameter' do
        old_message = create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'old',
                                                     created_at: 2.hours.ago)
        new_message = create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'new',
                                                     created_at: 1.minute.ago)

        get "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages",
            params: { after: (old_message.created_at + 1.second).iso8601 },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        message_ids = body['messages'].map { |m| m['id'] }
        expect(message_ids).to include(new_message.id)
        expect(message_ids).not_to include(old_message.id)
      end

      it 'includes reactions in message response' do
        message = create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'React to me')
        create(:internal_chat_reaction, message: message, user: agent, emoji: '👍')

        get "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['messages'].first['reactions'].length).to eq(1)
        expect(body['messages'].first['reactions'].first['emoji']).to eq('👍')
      end

      it 'includes sender information in message response' do
        create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'test')

        get "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['messages'].first['sender']).to be_present
      end

      it 'returns messages centered around a target message with around parameter' do
        messages = Array.new(10) do |i|
          create(:internal_chat_message, account: account, channel: channel, sender: agent,
                                         content: "msg-#{i}", created_at: (10 - i).minutes.ago)
        end
        target = messages[5]

        get "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages",
            params: { around: target.id },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        message_ids = body['messages'].map { |m| m['id'] }
        expect(message_ids).to include(target.id)
      end

      it 'excludes thread replies from the main listing by default' do
        parent = create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'parent msg')
        thread_reply = create(:internal_chat_message, account: account, channel: channel, sender: agent,
                                                      content: 'thread only reply', parent: parent)

        get "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages",
            headers: agent.create_new_auth_token,
            as: :json

        body = response.parsed_body
        ids = body['messages'].map { |m| m['id'] }
        expect(ids).to include(parent.id)
        expect(ids).not_to include(thread_reply.id)
      end

      it 'includes thread replies marked with also_send_in_channel in the main listing' do
        parent = create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'parent msg')
        broadcast_reply = create(:internal_chat_message, account: account, channel: channel, sender: agent,
                                                         content: 'broadcast reply', parent: parent,
                                                         content_attributes: { 'also_send_in_channel' => true })

        get "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages",
            headers: agent.create_new_auth_token,
            as: :json

        body = response.parsed_body
        ids = body['messages'].map { |m| m['id'] }
        expect(ids).to include(broadcast_reply.id)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/internal_chat/channels/:channel_id/messages' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages",
             params: { content: 'test' }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      it 'creates a new message in a public channel' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages",
             params: { content: 'Hello everyone!' },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['content']).to eq('Hello everyone!')
        expect(body['internal_chat_channel_id']).to eq(channel.id)
      end

      it 'creates a message with echo_id' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages",
             params: { content: 'test', echo_id: 'abc-123' },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['echo_id']).to eq('abc-123')
      end

      it 'creates a reply to a parent message' do
        parent = create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'parent')

        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages",
             params: { content: 'reply', parent_id: parent.id },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['parent_id']).to eq(parent.id)
      end

      it 'stores also_send_in_channel flag in content_attributes for thread replies' do
        parent = create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'parent')

        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages",
             params: { content: 'broadcast reply', parent_id: parent.id, also_send_in_channel: true },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['parent_id']).to eq(parent.id)
        expect(body['content_attributes']).to include('also_send_in_channel' => true)
      end

      it 'creates an attachment-only thread reply without content' do
        parent = create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'parent')
        file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')

        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages",
             params: { parent_id: parent.id, attachments: [{ file: file }] },
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['parent_id']).to eq(parent.id)
        expect(body['attachments'].size).to eq(1)
      end

      it 'creates a thread reply with attachment, content and also_send_in_channel via multipart' do
        parent = create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'parent')
        file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')

        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages",
             params: { content: 'see attached', parent_id: parent.id, also_send_in_channel: 'true', attachments: [{ file: file }] },
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['content']).to eq('see attached')
        expect(body['content_attributes']).to include('also_send_in_channel' => true)
        expect(body['attachments'].size).to eq(1)
      end

      it 'ignores also_send_in_channel when there is no parent_id' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages",
             params: { content: 'plain message', also_send_in_channel: true },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['content_attributes'] || {}).not_to have_key('also_send_in_channel')
      end

      it 'returns unauthorized for a private channel the agent is not a member of' do
        private_channel = create(:internal_chat_channel, :private_channel, account: account, name: 'secret')

        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{private_channel.id}/messages",
             params: { content: 'test' },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/internal_chat/channels/:channel_id/messages/:id' do
    let!(:message) { create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'original') }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages/#{message.id}",
              params: { content: 'updated' }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is the message sender' do
      it 'updates the message content' do
        patch "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages/#{message.id}",
              params: { content: 'updated content' },
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['content']).to eq('updated content')
        expect(body['content_attributes']['edited_at']).to be_present
        expect(body['content_attributes']['previous_content']).to eq('original')
      end
    end

    context 'when it is a different agent (not the sender)' do
      let(:other_agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages/#{message.id}",
              params: { content: 'hacked' },
              headers: other_agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an administrator (not the sender)' do
      it 'updates the message' do
        patch "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages/#{message.id}",
              params: { content: 'admin edited' },
              headers: administrator.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['content']).to eq('admin edited')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/internal_chat/channels/:channel_id/messages/:id' do
    let!(:message) { create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'to delete') }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages/#{message.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is the message sender' do
      it 'soft deletes the message' do
        delete "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages/#{message.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        message.reload
        expect(message.content_attributes['deleted']).to be(true)
      end
    end

    context 'when it is a different agent (not the sender)' do
      let(:other_agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages/#{message.id}",
               headers: other_agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an administrator' do
      it 'soft deletes the message' do
        delete "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages/#{message.id}",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        message.reload
        expect(message.content_attributes['deleted']).to be(true)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/internal_chat/channels/:channel_id/messages/:id/pin' do
    let!(:message) { create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'pin me') }

    context 'when it is an authenticated administrator' do
      it 'pins the message' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages/#{message.id}/pin",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['content_attributes']['pinned']).to be(true)
        expect(body['content_attributes']['pinned_by']).to eq(administrator.id)
        expect(body['content_attributes']['pinned_at']).to be_present
      end
    end

    context 'when it is a channel admin member' do
      it 'pins the message' do
        channel.channel_members.find_or_create_by!(user: agent).update!(role: :admin)

        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages/#{message.id}/pin",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['content_attributes']['pinned']).to be(true)
      end
    end

    context 'when it is a regular agent (not channel admin)' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages/#{message.id}/pin",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/internal_chat/channels/:channel_id/messages/:id/unpin' do
    let!(:message) do
      create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'pinned msg',
                                     content_attributes: { 'pinned' => true, 'pinned_by' => administrator.id,
                                                           'pinned_at' => Time.current.iso8601 })
    end

    context 'when it is an authenticated administrator' do
      it 'unpins the message' do
        delete "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages/#{message.id}/unpin",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['content_attributes']).not_to have_key('pinned')
      end
    end
  end

  describe 'GET /api/v1/accounts/:account_id/internal_chat/channels/:channel_id/messages/:id/thread' do
    let!(:parent_message) { create(:internal_chat_message, account: account, channel: channel, sender: agent, content: 'thread starter') }

    context 'when it is an authenticated agent' do
      it 'returns the thread with parent and replies' do
        reply = create(:internal_chat_message, account: account, channel: channel, sender: agent,
                                               content: 'reply', parent: parent_message)

        get "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages/#{parent_message.id}/thread",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['parent']['id']).to eq(parent_message.id)
        expect(body['replies'].length).to eq(1)
        expect(body['replies'].first['id']).to eq(reply.id)
      end

      it 'returns empty replies when there are no thread replies' do
        get "/api/v1/accounts/#{account.id}/internal_chat/channels/#{channel.id}/messages/#{parent_message.id}/thread",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['parent']['id']).to eq(parent_message.id)
        expect(body['replies']).to eq([])
      end
    end
  end
end
