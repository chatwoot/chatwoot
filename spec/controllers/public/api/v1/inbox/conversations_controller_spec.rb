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
      data = JSON.parse(response.body)
      expect(data.length).to eq 1
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
      data = JSON.parse(response.body)
      expect(data.length).to eq 1
      expect(data.first['messages'].length).to eq 2
      expect(data.first['messages'].map { |m| m['content'] }).not_to include('private-message-1')
      expect(data.first['messages'].map { |m| m['message_type'] }).not_to include('activity')
    end
  end

  describe 'POST /public/api/v1/inboxes/{identifier}/contact/{source_id}/conversations' do
    it 'creates a conversation for that contact' do
      post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations"

      expect(response).to have_http_status(:success)
      data = JSON.parse(response.body)
      expect(data['id']).not_to be_nil
    end
  end
end
