require 'rails_helper'

RSpec.describe 'Conversation GroupContacts API', type: :request do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account, group: true) }
  let(:agent) { create(:user, account: account, role: :agent) }

  before do
    create(:inbox_member, inbox: conversation.inbox, user: agent)
  end

  describe 'GET /api/v1/accounts/{account.id}/conversations/<id>/group_contacts' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get api_v1_account_conversation_group_contacts_url(account_id: account.id, conversation_id: conversation.display_id)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with access to the conversation' do
      let(:contact1) { create(:contact, account: account) }
      let(:contact2) { create(:contact, account: account) }

      it 'returns paginated group contacts with meta information' do
        create(:group_contact, conversation: conversation, contact: contact1, account: account)
        create(:group_contact, conversation: conversation, contact: contact2, account: account)
        get api_v1_account_conversation_group_contacts_url(account_id: account.id, conversation_id: conversation.display_id),
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        expect(response_body['meta']['count']).to eq(2)
        expect(response_body['meta']['current_page']).to eq(1)
        expect(response_body['payload'].length).to eq(2)
      end

      it 'returns correct page of results when page parameter is provided' do
        contacts = create_list(:contact, 101, account: account)
        contacts.each { |contact| create(:group_contact, conversation: conversation, contact: contact, account: account) }

        get api_v1_account_conversation_group_contacts_url(account_id: account.id, conversation_id: conversation.display_id),
            params: { page: 2 },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        expect(response_body['meta']['count']).to eq(101)
        expect(response_body['meta']['current_page']).to eq(2)
        expect(response_body['payload'].length).to eq(1)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/<id>/group_contacts' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post api_v1_account_conversation_group_contacts_url(account_id: account.id, conversation_id: conversation.display_id)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:contact) { create(:contact, account: account) }

      it 'creates new group contacts when conversation is a group' do
        params = { contact_ids: [contact.id] }

        expect(conversation.group_contacts.count).to eq(0)
        post api_v1_account_conversation_group_contacts_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.group_contacts.count).to eq(1)
      end

      it 'returns error when conversation is not a group' do
        non_group_conversation = create(:conversation, account: account, group: false)
        create(:inbox_member, inbox: non_group_conversation.inbox, user: agent)
        params = { contact_ids: [contact.id] }

        post api_v1_account_conversation_group_contacts_url(account_id: account.id, conversation_id: non_group_conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Conversation must be a group')
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/conversations/<id>/group_contacts' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put api_v1_account_conversation_group_contacts_url(account_id: account.id, conversation_id: conversation.display_id)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:contact) { create(:contact, account: account) }
      let(:contact_to_be_added) { create(:contact, account: account) }
      let(:contact_to_be_removed) { create(:contact, account: account) }

      it 'updates group contacts when conversation is a group' do
        params = { contact_ids: [contact.id, contact_to_be_added.id] }
        create(:group_contact, conversation: conversation, contact: contact, account: account)
        create(:group_contact, conversation: conversation, contact: contact_to_be_removed, account: account)

        expect(conversation.group_contacts.count).to eq(2)
        put api_v1_account_conversation_group_contacts_url(account_id: account.id, conversation_id: conversation.display_id),
            params: params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.group_contacts.count).to eq(2)
        expect(conversation.group_contacts.pluck(:contact_id)).to contain_exactly(contact.id, contact_to_be_added.id)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/conversations/<id>/group_contacts' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete api_v1_account_conversation_group_contacts_url(account_id: account.id, conversation_id: conversation.display_id)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:contact) { create(:contact, account: account) }

      it 'deletes group contacts when its authorized agent' do
        params = { contact_ids: [contact.id] }
        create(:group_contact, conversation: conversation, contact: contact, account: account)

        expect(conversation.group_contacts.count).to eq(1)
        delete api_v1_account_conversation_group_contacts_url(account_id: account.id, conversation_id: conversation.display_id),
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.group_contacts.count).to eq(0)
      end
    end
  end
end
