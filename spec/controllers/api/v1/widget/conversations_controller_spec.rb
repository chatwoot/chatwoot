require 'rails_helper'

RSpec.describe '/api/v1/widget/conversations/toggle_typing', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let!(:conversation) { create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { ::Widget::TokenService.new(payload: payload).generate_token }

  describe 'GET /api/v1/widget/conversations' do
    it 'returns a list of conversations' do
      allow(Rails.configuration.dispatcher).to receive(:dispatch)
      get api_v1_widget_conversations_url,
          headers: { 'X-Auth-Token' => token },
          params: { website_token: web_widget.website_token },
          as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq 1
      expect(json_response[0]['id']).to eq(conversation.display_id)
      expect(json_response[0]['status']).to eq(conversation.status)
    end
  end

  describe 'POST /api/v1/widget/conversations' do
    it 'returns error if message params are not present' do
      allow(Rails.configuration.dispatcher).to receive(:dispatch)
      post api_v1_widget_conversations_url,
           headers: { 'X-Auth-Token' => token },
           params: { website_token: web_widget.website_token },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'creates a conversation if message params are present' do
      allow(Rails.configuration.dispatcher).to receive(:dispatch)
      post api_v1_widget_conversations_url,
           headers: { 'X-Auth-Token' => token },
           params: { website_token: web_widget.website_token, message: { content: 'Test message' } },
           as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['messages'].count).to eq 1
      expect(json_response['messages'][0]['content']).to eq 'Test message'
    end
  end

  describe 'POST /api/v1/widget/conversations/:id/toggle_typing' do
    it 'dispatches the correct typing status' do
      allow(Rails.configuration.dispatcher).to receive(:dispatch)
      post toggle_typing_api_v1_widget_conversation_url(id: conversation.display_id),
           headers: { 'X-Auth-Token' => token },
           params: { typing_status: 'on', website_token: web_widget.website_token },
           as: :json

      expect(response).to have_http_status(:success)
      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(Conversation::CONVERSATION_TYPING_ON, kind_of(Time), { conversation: conversation, user: contact })
    end
  end

  describe 'POST /api/v1/widget/conversations/update_last_seen' do
    it 'returns the correct conversation params' do
      allow(Rails.configuration.dispatcher).to receive(:dispatch)
      expect(conversation.contact_last_seen_at).to eq(nil)

      post update_last_seen_api_v1_widget_conversation_url(id: conversation.display_id),
           headers: { 'X-Auth-Token' => token },
           params: { website_token: web_widget.website_token },
           as: :json

      expect(response).to have_http_status(:success)
      expect(conversation.reload.contact_last_seen_at).not_to eq(nil)
    end
  end

  describe 'POST /api/v1/widget/conversations/transcript' do
    it 'sends transcript email' do
      allow(ConversationReplyMailer).to receive(:conversation_transcript)

      post transcript_api_v1_widget_conversation_url(id: conversation.display_id),
           headers: { 'X-Auth-Token' => token },
           params: { website_token: web_widget.website_token, email: 'test@test.com' },
           as: :json

      expect(response).to have_http_status(:success)
      expect(ConversationReplyMailer).to have_received(:conversation_transcript).with(conversation, 'test@test.com')
    end
  end
end
