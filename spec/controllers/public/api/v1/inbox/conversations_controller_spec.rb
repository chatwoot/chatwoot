require 'rails_helper'

RSpec.describe 'Public Inbox Contact Conversations API', type: :request do
  let!(:api_channel) { create(:channel_api) }
  let!(:contact) { create(:contact) }
  let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: api_channel.inbox) }

  describe 'GET /public/api/v1/inboxes/{identifier}/contact/{source_id}/conversations' do
    it 'return the conversations for that contact' do
      create(:conversation, contact_inbox: contact_inbox)
      get "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations"

      expect(response).to have_http_status(:success)
      data = response.parsed_body
      expect(data.length).to eq 1
      expect(data.first['uuid']).to eq contact_inbox.conversations.first.uuid
    end

    it 'does not return any private or activity message' do
      conversation = create(:conversation, contact_inbox: contact_inbox)
      create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, content: 'message-1')
      create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, content: 'message-2')
      create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, content: 'private-message-1',
                       private: true)
      create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, content: 'activity-message-1',
                       message_type: :activity)

      get "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations"

      expect(response).to have_http_status(:success)
      data = response.parsed_body
      expect(data.length).to eq 1
      expect(data.first['messages'].length).to eq 2
      expect(data.first['messages'].pluck('content')).not_to include('private-message-1')
      expect(data.first['messages'].pluck('message_type')).not_to include('activity')
    end
  end

  describe 'POST /public/api/v1/inboxes/{identifier}/contact/{source_id}/conversations' do
    it 'creates a conversation for that contact' do
      post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations"

      expect(response).to have_http_status(:success)
      data = response.parsed_body
      expect(data['id']).not_to be_nil
    end

    it 'creates a conversation with custom attributes but prevents other attributes' do
      post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations",
           params: { custom_attributes: { 'test' => 'test' }, additional_attributes: { 'test' => 'test' } }

      expect(response).to have_http_status(:success)
      data = response.parsed_body
      conversation = api_channel.inbox.conversations.find_by(display_id: data['id'])
      expect(conversation.custom_attributes).to eq('test' => 'test')
      expect(conversation.additional_attributes).to be_empty
    end
  end

  describe 'POST /public/api/v1/inboxes/{identifier}/contact/{source_id}/conversations/{conversation_id}/toggle_typing' do
    let!(:conversation) { create(:conversation, contact_inbox: contact_inbox, contact: contact) }
    let(:toggle_typing_path) do
      "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations/#{conversation.display_id}/toggle_typing"
    end

    it 'dispatches the correct typing status' do
      allow(Rails.configuration.dispatcher).to receive(:dispatch)
      post toggle_typing_path, params: { typing_status: 'on' }

      expect(response).to have_http_status(:success)
      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(Conversation::CONVERSATION_TYPING_ON, kind_of(Time), { conversation: conversation, user: contact })
    end
  end

  describe 'POST /public/api/v1/inboxes/{identifier}/contact/{source_id}/conversations/{conversation_id}/update_last_seen' do
    let!(:conversation) { create(:conversation, contact_inbox: contact_inbox, contact: contact) }
    let(:update_last_seen_path) do
      "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations/#{conversation.display_id}/update_last_seen"
    end

    it 'updates the last seen of the conversation contact' do
      current_time = DateTime.now.utc
      allow(DateTime).to receive(:now).and_return(current_time)
      contact_last_seen_at = conversation.contact_last_seen_at
      expect(Conversations::UpdateMessageStatusJob).to receive(:perform_later).with(conversation.id, current_time)
      post update_last_seen_path

      expect(response).to have_http_status(:success)
      expect(conversation.reload.contact_last_seen_at).not_to eq contact_last_seen_at
    end
  end
end
