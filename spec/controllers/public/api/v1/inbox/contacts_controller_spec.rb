require 'rails_helper'

RSpec.describe 'Public Inbox Contacts API', type: :request do
  let!(:api_channel) { create(:channel_api) }
  let!(:contact) { create(:contact) }
  let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: api_channel.inbox) }

  describe 'POST /public/api/v1/inboxes/{identifier}/contact' do
    it 'creates a contact and return the source id' do
      post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts"

      expect(response).to have_http_status(:success)
      data = response.parsed_body
      expect(data.keys).to include('email', 'id', 'name', 'phone_number', 'pubsub_token', 'source_id')
      expect(data['source_id']).not_to be_nil
      expect(data['pubsub_token']).not_to be_nil
    end

    it 'persists the identifier of the contact' do
      identifier = 'contact-identifier'
      post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts", params: { identifier: identifier }

      expect(response).to have_http_status(:success)
      db_contact = api_channel.account.contacts.find_by(identifier: identifier)
      expect(db_contact).not_to be_nil
    end
  end

  describe 'GET /public/api/v1/inboxes/{identifier}/contact/{source_id}' do
    it 'gets a contact when present' do
      get "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}"

      expect(response).to have_http_status(:success)
      data = response.parsed_body
      expect(data.keys).to include('email', 'id', 'name', 'phone_number', 'pubsub_token', 'source_id')
      expect(data['source_id']).to eq contact_inbox.source_id
      expect(data['pubsub_token']).to eq contact_inbox.pubsub_token
    end
  end

  describe 'PATCH /public/api/v1/inboxes/{identifier}/contact/{source_id}' do
    it 'updates a contact when present' do
      patch "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}",
            params: { name: 'John Smith' }

      expect(response).to have_http_status(:success)
      data = response.parsed_body
      expect(data['name']).to eq 'John Smith'
    end
  end
end
