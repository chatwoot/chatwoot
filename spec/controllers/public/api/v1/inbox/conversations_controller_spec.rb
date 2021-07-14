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
  end

  describe 'POST /public/api/v1/inboxes/{identifier}/contact/{source_id}/conversations' do
    it 'creates a conversation for that contact' do
      post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations"

      expect(response).to have_http_status(:success)
      data = JSON.parse(response.body)
      expect(data['id']).not_to eq nil
    end
  end
end
