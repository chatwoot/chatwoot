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

  describe 'HMAC identifier binding' do
    let!(:owner_contact) { create(:contact, account: api_channel.account, identifier: 'owner-identifier') }
    let!(:owner_inbox) { create(:contact_inbox, contact: owner_contact, inbox: api_channel.inbox) }
    let!(:victim_contact) { create(:contact, account: api_channel.account, identifier: 'victim-identifier', name: 'Victim') }
    let!(:victim_inbox) { create(:contact_inbox, contact: victim_contact, inbox: api_channel.inbox) }
    let(:valid_owner_hash) { OpenSSL::HMAC.hexdigest('sha256', api_channel.hmac_token, 'owner-identifier') }

    it 'does not promote the victim contact inbox to hmac_verified when a valid pair is replayed against the victim source_id' do
      begin
        get "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{victim_inbox.source_id}",
            params: { identifier: 'owner-identifier', identifier_hash: valid_owner_hash }
      rescue StandardError
        # the fix fails closed by raising; the security invariant is asserted below
      end

      expect(victim_inbox.reload.hmac_verified).to be(false)
    end

    it 'does not mutate the victim contact when a valid pair is replayed against the victim source_id' do
      begin
        patch "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{victim_inbox.source_id}",
              params: { identifier: 'owner-identifier', identifier_hash: valid_owner_hash, name: 'Hacked' }
      rescue StandardError
        # the fix fails closed by raising; the security invariant is asserted below
      end

      expect(victim_contact.reload.name).to eq('Victim')
    end

    it 'still verifies the contact inbox when the owner presents a matching identifier pair' do
      get "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{owner_inbox.source_id}",
          params: { identifier: 'owner-identifier', identifier_hash: valid_owner_hash }

      expect(response).to have_http_status(:success)
      expect(owner_inbox.reload.hmac_verified).to be(true)
    end

    it 'does not verify an anonymous contact inbox when a valid pair is replayed against its source_id' do
      anonymous_contact = create(:contact, account: api_channel.account)
      anonymous_inbox = create(:contact_inbox, contact: anonymous_contact, inbox: api_channel.inbox)

      get "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{anonymous_inbox.source_id}",
          params: { identifier: 'owner-identifier', identifier_hash: valid_owner_hash }

      expect(anonymous_inbox.reload.hmac_verified).to be(false)
    end
  end
end
