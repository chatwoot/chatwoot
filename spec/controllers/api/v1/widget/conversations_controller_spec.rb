require 'rails_helper'

RSpec.describe '/api/v1/widget/conversations/toggle_typing', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account, email: nil) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let!(:conversation) { create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { ::Widget::TokenService.new(payload: payload).generate_token }

  describe 'GET /api/v1/widget/conversations' do
    context 'with a conversation' do
      it 'returns the correct conversation params' do
        allow(Rails.configuration.dispatcher).to receive(:dispatch)
        get '/api/v1/widget/conversations',
            headers: { 'X-Auth-Token' => token },
            params: { website_token: web_widget.website_token },
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)

        expect(json_response['id']).to eq(conversation.display_id)
        expect(json_response['status']).to eq(conversation.status)
      end
    end
  end

  describe 'POST /api/v1/widget/conversations/toggle_typing' do
    context 'with a conversation' do
      it 'dispatches the correct typing status' do
        allow(Rails.configuration.dispatcher).to receive(:dispatch)
        post '/api/v1/widget/conversations/toggle_typing',
             headers: { 'X-Auth-Token' => token },
             params: { typing_status: 'on', website_token: web_widget.website_token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(Conversation::CONVERSATION_TYPING_ON, kind_of(Time), { conversation: conversation, user: contact })
      end
    end
  end

  describe 'POST /api/v1/widget/conversations/update_last_seen' do
    context 'with a conversation' do
      it 'returns the correct conversation params' do
        allow(Rails.configuration.dispatcher).to receive(:dispatch)
        expect(conversation.user_last_seen_at).to eq(nil)

        post '/api/v1/widget/conversations/update_last_seen',
             headers: { 'X-Auth-Token' => token },
             params: { website_token: web_widget.website_token },
             as: :json

        expect(response).to have_http_status(:success)

        expect(conversation.reload.user_last_seen_at).not_to eq(nil)
      end
    end
  end
end
