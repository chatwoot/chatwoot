require 'rails_helper'

RSpec.describe 'Public Inbox Contact Conversation Messages API', type: :request do
  let!(:api_channel) { create(:channel_api) }
  let!(:contact) { create(:contact, phone_number: '+324234324', email: 'dfsadf@sfsda.com') }
  let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: api_channel.inbox) }
  let!(:conversation)  { create(:conversation, contact: contact, contact_inbox: contact_inbox) }

  describe 'GET /public/api/v1/inboxes/{identifier}/contact/{source_id}/conversations/{conversation_id}/messages' do
    it 'return the messages for that conversation' do
      2.times.each { create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation) }

      get "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations/#{conversation.display_id}/messages"

      expect(response).to have_http_status(:success)
      data = response.parsed_body
      expect(data.length).to eq 2
    end
  end

  describe 'POST /public/api/v1/inboxes/{identifier}/contact/{source_id}/conversations/{conversation_id}/messages' do
    it 'creates a message in the conversation' do
      post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations/#{conversation.display_id}/messages",
           params: { content: 'hello' }

      expect(response).to have_http_status(:success)
      data = response.parsed_body
      expect(data['content']).to eq('hello')
    end

    it 'does not create the message' do
      content = "#{'h' * 150 * 1000}a"
      post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations/#{conversation.display_id}/messages",
           params: { content: content }

      expect(response).to have_http_status(:unprocessable_entity)

      json_response = response.parsed_body

      expect(json_response['message']).to eq('Content is too long (maximum is 150000 characters)')
    end

    it 'creates attachment message in conversation' do
      file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')
      post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations/#{conversation.display_id}/messages",
           params: { content: 'hello', attachments: [file] }

      expect(response).to have_http_status(:success)
      data = response.parsed_body
      expect(data['content']).to eq('hello')

      expect(conversation.messages.last.attachments.first.file.present?).to be(true)
      expect(conversation.messages.last.attachments.first.file_type).to eq('image')
    end

    context 'with sender_identifier in group conversations' do
      # Use the same account for all test objects
      let!(:account) { api_channel.inbox.account }
      let!(:group_contact_obj) { create(:contact, account: account, identifier: 'group-primary') }
      let!(:group_contact_inbox) { create(:contact_inbox, contact: group_contact_obj, inbox: api_channel.inbox) }
      let!(:group_conversation) do
        create(:conversation, account: account, inbox: api_channel.inbox,
                              contact: group_contact_obj, contact_inbox: group_contact_inbox, group: true)
      end
      let!(:group_member) { create(:contact, account: account, identifier: 'member-001') }

      before do
        create(:group_contact, conversation: group_conversation, contact: group_member, account: account)
      end

      it 'uses the group member as sender when sender_identifier matches' do
        url = "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{group_contact_inbox.source_id}" \
              "/conversations/#{group_conversation.display_id}/messages"
        post url, params: { content: 'hello from member', sender_identifier: 'member-001' }

        expect(response).to have_http_status(:success)
        message = group_conversation.messages.reload.last
        expect(message).not_to be_nil
        expect(message.sender).to eq(group_member)
      end

      it 'falls back to primary contact when sender_identifier not found' do
        url = "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{group_contact_inbox.source_id}" \
              "/conversations/#{group_conversation.display_id}/messages"
        post url, params: { content: 'hello', sender_identifier: 'unknown-identifier' }

        expect(response).to have_http_status(:success)
        message = group_conversation.messages.reload.last
        expect(message).not_to be_nil
        expect(message.sender).to eq(group_contact_obj)
      end

      it 'falls back to primary contact when sender_identifier belongs to contact not in group' do
        create(:contact, account: account, identifier: 'outside-001')
        url = "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{group_contact_inbox.source_id}" \
              "/conversations/#{group_conversation.display_id}/messages"
        post url, params: { content: 'hello', sender_identifier: 'outside-001' }

        expect(response).to have_http_status(:success)
        message = group_conversation.messages.reload.last
        expect(message).not_to be_nil
        expect(message.sender).to eq(group_contact_obj)
      end

      it 'ignores sender_identifier for non-group conversations' do
        post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations/#{conversation.display_id}/messages",
             params: { content: 'hello', sender_identifier: 'member-001' }

        expect(response).to have_http_status(:success)
        message = conversation.messages.reload.last
        expect(message.sender).to eq(contact)
      end
    end
  end

  describe 'PATCH /public/api/v1/inboxes/{identifier}/contact/{source_id}/conversations/{conversation_id}/messages/{id}' do
    it 'updates a message in the conversation' do
      message = create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation)
      patch "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations/" \
            "#{conversation.display_id}/messages/#{message.id}",
            params: { submitted_values: [{ title: 'test' }] }

      expect(response).to have_http_status(:success)
      data = response.parsed_body
      expect(data['content_attributes']['submitted_values'].first['title']).to eq 'test'
    end

    it 'updates CSAT survey response for the conversation' do
      message = create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, content_type: 'input_csat')
      # since csat survey is created in async job, we are mocking the creation.
      create(:csat_survey_response, conversation: conversation, message: message, rating: 4, feedback_message: 'amazing experience')

      patch "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations/" \
            "#{conversation.display_id}/messages/#{message.id}",
            params: { submitted_values: { csat_survey_response: { rating: 4, feedback_message: 'amazing experience' } } },
            as: :json

      expect(response).to have_http_status(:success)
      data = response.parsed_body
      expect(data['content_attributes']['submitted_values']['csat_survey_response']['feedback_message']).to eq 'amazing experience'
      expect(data['content_attributes']['submitted_values']['csat_survey_response']['rating']).to eq 4
    end

    it 'returns update error if CSAT message sent more than 14 days' do
      message = create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation, content_type: 'input_csat',
                                 created_at: 15.days.ago)
      # since csat survey is created in async job, we are mocking the creation.
      create(:csat_survey_response, conversation: conversation, message: message, rating: 4, feedback_message: 'amazing experience')

      patch "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations/" \
            "#{conversation.display_id}/messages/#{message.id}",
            params: { submitted_values: { csat_survey_response: { rating: 4, feedback_message: 'amazing experience' } } },
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
