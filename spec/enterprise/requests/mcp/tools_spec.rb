require 'rails_helper'

RSpec.describe 'MCP tools', type: :request do
  include McpSpecHelpers

  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:application) { Doorkeeper::Application.create!(name: 'ChatGPT', redirect_uri: 'https://chatgpt.com/callback', confidential: false) }
  let(:scopes) { 'conversations:read conversations:write contacts:read messages:write' }
  let(:access_token) do
    Doorkeeper::AccessToken.create!(application: application, resource_owner_id: agent.id, account_id: account.id, scopes: scopes,
                                    expires_in: 2.hours)
  end

  before do
    InstallationConfig.where(name: 'OAUTH_PROVIDER_ENABLED').delete_all
    InstallationConfig.create!(name: 'OAUTH_PROVIDER_ENABLED', value: true)
    create(:inbox_member, inbox: inbox, user: agent)
  end

  after { GlobalConfig.clear_cache }

  describe 'tools/list' do
    it 'lists every tool with the OAuth scope it needs' do
      tools = mcp_request('tools/list', {}, access_token)['tools']

      expect(tools.to_h { |tool| [tool['name'], tool['securitySchemes']] }).to eq(
        'list_conversations' => [{ 'type' => 'oauth2', 'scopes' => ['conversations:read'] }],
        'get_conversation' => [{ 'type' => 'oauth2', 'scopes' => ['conversations:read'] }],
        'update_conversation' => [{ 'type' => 'oauth2', 'scopes' => ['conversations:write'] }],
        'search_contacts' => [{ 'type' => 'oauth2', 'scopes' => ['contacts:read'] }],
        'send_message' => [{ 'type' => 'oauth2', 'scopes' => ['messages:write'] }]
      )
    end

    it 'marks which tools only read' do
      tools = mcp_request('tools/list', {}, access_token)['tools']

      expect(tools.to_h { |tool| [tool['name'], tool.dig('annotations', 'readOnlyHint')] }).to eq(
        'list_conversations' => true, 'get_conversation' => true, 'update_conversation' => false, 'search_contacts' => true,
        'send_message' => false
      )
    end
  end

  describe 'a tool call without the required scope' do
    let(:scopes) { 'conversations:read' }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }

    it 'returns an insufficient_scope challenge and does nothing' do
      result = with_modified_env FRONTEND_URL: 'https://support.example.com' do
        call_mcp_tool('send_message', { conversation_id: conversation.display_id, content: 'Hello' }, access_token)
      end

      expect(result['isError']).to be(true)
      expect(result.dig('_meta', 'mcp/www_authenticate')).to eq(
        ['Bearer resource_metadata="https://support.example.com/.well-known/oauth-protected-resource/mcp", ' \
         'error="insufficient_scope", error_description="This action needs the messages:write scope"']
      )
      expect(conversation.messages.count).to eq(0)
    end
  end

  describe 'list_conversations' do
    let!(:conversation) { create(:conversation, account: account, inbox: inbox, status: :open) }

    it 'returns the open conversations the agent can access' do
      contact_name = conversation.contact.name
      create(:message, conversation: conversation, account: account, inbox: inbox, content: 'Where is my order?')

      result = call_mcp_tool('list_conversations', {}, access_token)

      expect(result['isError']).to be(false)
      expect(result['structuredContent']['conversations']).to contain_exactly(
        include('id' => conversation.display_id, 'status' => 'open', 'inbox' => inbox.name, 'contact' => contact_name,
                'last_message' => 'Where is my order?')
      )
    end

    it 'leaves out conversations in inboxes the agent is not a member of' do
      create(:conversation, account: account, inbox: create(:inbox, account: account))

      result = call_mcp_tool('list_conversations', {}, access_token)

      expect(result['structuredContent']['conversations'].pluck('id')).to eq([conversation.display_id])
    end

    it 'leaves out conversations of other accounts' do
      create(:conversation)

      result = call_mcp_tool('list_conversations', { status: 'all' }, access_token)

      expect(result['structuredContent']['conversations'].pluck('id')).to eq([conversation.display_id])
    end

    it 'filters by status' do
      resolved = create(:conversation, account: account, inbox: inbox, status: :resolved)

      result = call_mcp_tool('list_conversations', { status: 'resolved' }, access_token)

      expect(result['structuredContent']['conversations'].pluck('id')).to eq([resolved.display_id])
    end

    it 'filters by assignment to the user' do
      mine = create(:conversation, account: account, inbox: inbox, assignee: agent)

      result = call_mcp_tool('list_conversations', { assignee_type: 'me' }, access_token)

      expect(result['structuredContent']['conversations'].pluck('id')).to eq([mine.display_id])
      expect(result['structuredContent']['conversations'].first['assignee']).to eq(agent.name)
    end

    it 'rejects a status the schema does not define' do
      result = call_mcp_tool('list_conversations', { status: 'deleted' }, access_token)

      expect(result['isError']).to be(true)
      expect(result['content'].first['text']).to include('/status')
    end
  end

  describe 'get_conversation' do
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }

    it 'returns the conversation with its messages, oldest first' do
      create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming, content: 'Where is my order?')
      create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :outgoing, sender: agent, private: true,
                       content: 'Checking with shipping')
      create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :activity, content: 'Assigned to agent')

      result = call_mcp_tool('get_conversation', { conversation_id: conversation.display_id }, access_token)

      expect(result['structuredContent']).to include('id' => conversation.display_id, 'status' => 'open')
      expect(result['structuredContent']['messages']).to match(
        [
          include('content' => 'Where is my order?', 'type' => 'incoming', 'private' => false),
          include('content' => 'Checking with shipping', 'type' => 'outgoing', 'private' => true, 'sender' => agent.name)
        ]
      )
    end

    it 'returns an error for a conversation in an inbox the agent cannot access' do
      hidden = create(:conversation, account: account, inbox: create(:inbox, account: account))

      result = call_mcp_tool('get_conversation', { conversation_id: hidden.display_id }, access_token)

      expect(result['isError']).to be(true)
      expect(result['structuredContent']).to be_nil
    end

    it 'returns an error for a conversation of another account' do
      other = create(:conversation)

      result = call_mcp_tool('get_conversation', { conversation_id: other.display_id }, access_token)

      expect(result['isError']).to be(true)
    end
  end

  describe 'update_conversation' do
    let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :open) }

    before do
      create(:label, account: account, title: 'billing')
      create(:label, account: account, title: 'vip')
    end

    it 'changes the status' do
      result = call_mcp_tool('update_conversation', { conversation_id: conversation.display_id, status: 'resolved' }, access_token)

      expect(result['isError']).to be(false)
      expect(result['structuredContent']).to include('id' => conversation.display_id, 'status' => 'resolved')
      expect(conversation.reload).to be_resolved
    end

    it 'assigns the conversation to the user when an agent reopens it, as the dashboard does' do
      conversation.update!(status: :resolved)

      call_mcp_tool('update_conversation', { conversation_id: conversation.display_id, status: 'open' }, access_token)

      expect(conversation.reload).to have_attributes(status: 'open', assignee: agent)
    end

    it 'sets and clears the priority' do
      call_mcp_tool('update_conversation', { conversation_id: conversation.display_id, priority: 'urgent' }, access_token)
      expect(conversation.reload.priority).to eq('urgent')

      call_mcp_tool('update_conversation', { conversation_id: conversation.display_id, priority: 'none' }, access_token)
      expect(conversation.reload.priority).to be_nil
    end

    it 'replaces the labels' do
      conversation.update_labels(['vip'])

      result = call_mcp_tool('update_conversation', { conversation_id: conversation.display_id, labels: ['billing'] }, access_token)

      expect(conversation.reload.label_list).to eq(['billing'])
      expect(result['structuredContent']['labels']).to eq(['billing'])
    end

    it 'removes every label for an empty list' do
      conversation.update_labels(['vip'])

      call_mcp_tool('update_conversation', { conversation_id: conversation.display_id, labels: [] }, access_token)

      expect(conversation.reload.label_list).to be_empty
    end

    it 'rejects a label the account does not have and names the ones it has' do
      result = call_mcp_tool('update_conversation', { conversation_id: conversation.display_id, labels: %w[billing refunds], status: 'resolved' },
                             access_token)

      expect(result['isError']).to be(true)
      expect(result['content'].first['text']).to include('refunds', 'billing, vip')
      expect(conversation.reload).to have_attributes(status: 'open', label_list: [])
    end

    it 'assigns the conversation to the user' do
      result = call_mcp_tool('update_conversation', { conversation_id: conversation.display_id, assignee: 'me' }, access_token)

      expect(conversation.reload.assignee).to eq(agent)
      expect(result['structuredContent']['assignee']).to eq(agent.name)
    end

    it 'unassigns the conversation' do
      conversation.update!(assignee: agent)

      call_mcp_tool('update_conversation', { conversation_id: conversation.display_id, assignee: 'none' }, access_token)

      expect(conversation.reload.assignee).to be_nil
    end

    it 'applies several changes in one call' do
      call_mcp_tool('update_conversation',
                    { conversation_id: conversation.display_id, status: 'pending', priority: 'high', labels: ['vip'], assignee: 'me' },
                    access_token)

      expect(conversation.reload).to have_attributes(status: 'pending', priority: 'high', label_list: ['vip'], assignee: agent)
    end

    it 'does not change a conversation in an inbox the agent cannot access' do
      hidden = create(:conversation, account: account, inbox: create(:inbox, account: account), status: :open)

      result = call_mcp_tool('update_conversation', { conversation_id: hidden.display_id, status: 'resolved' }, access_token)

      expect(result['isError']).to be(true)
      expect(hidden.reload).to be_open
    end

    context 'when the token lacks conversations:write' do
      let(:scopes) { 'conversations:read' }

      it 'returns an insufficient_scope challenge and changes nothing' do
        result = call_mcp_tool('update_conversation', { conversation_id: conversation.display_id, status: 'resolved' }, access_token)

        expect(result.dig('_meta', 'mcp/www_authenticate').first).to include('insufficient_scope', 'conversations:write')
        expect(conversation.reload).to be_open
      end
    end
  end

  describe 'search_contacts' do
    it 'finds contacts of the account by name, email or phone number' do
      contact = create(:contact, account: account, name: 'Jane Cooper', email: 'jane@example.com', phone_number: '+14155550100')
      create(:contact, account: account, name: 'Robert Fox')
      create(:contact, name: 'Jane Other Account')

      %w[cooper jane@example 4155550100].each do |query|
        result = call_mcp_tool('search_contacts', { query: query }, access_token)

        expect(result['structuredContent']['contacts']).to contain_exactly(
          include('id' => contact.id, 'name' => 'Jane Cooper', 'email' => 'jane@example.com', 'phone_number' => '+14155550100')
        )
      end
    end
  end

  describe 'send_message' do
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }

    it 'sends a reply to the customer as the user' do
      result = call_mcp_tool('send_message', { conversation_id: conversation.display_id, content: 'Your order ships today' }, access_token)

      message = conversation.messages.last
      expect(result['isError']).to be(false)
      expect(message).to have_attributes(content: 'Your order ships today', message_type: 'outgoing', private: false, sender: agent)
      expect(result['structuredContent']).to include('id' => message.id, 'private' => false)
    end

    it 'adds a private note when asked' do
      call_mcp_tool('send_message', { conversation_id: conversation.display_id, content: 'Refund approved', private: true }, access_token)

      expect(conversation.messages.last).to have_attributes(content: 'Refund approved', private: true, sender: agent)
    end

    it 'does not send to a conversation in an inbox the agent cannot access' do
      hidden = create(:conversation, account: account, inbox: create(:inbox, account: account))

      result = call_mcp_tool('send_message', { conversation_id: hidden.display_id, content: 'Hello' }, access_token)

      expect(result['isError']).to be(true)
      expect(hidden.messages.count).to eq(0)
    end
  end
end
