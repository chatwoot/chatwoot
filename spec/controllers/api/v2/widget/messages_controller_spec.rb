require 'rails_helper'

RSpec.describe '/api/v2/widget/conversations/:display_id/messages', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let!(:conversation) do
    create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox)
  end
  let(:token) do
    Widget::TokenService.new(payload: { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id }).generate_token
  end
  let(:headers) { { 'X-Auth-Token' => token } }

  before do
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
  end

  describe 'GET messages' do
    let!(:message) { create(:message, conversation: conversation, account: account, content: 'hello from agent', message_type: :outgoing) }

    it 'returns messages of the requested conversation' do
      get "/api/v2/widget/conversations/#{conversation.display_id}/messages",
          headers: headers,
          params: { website_token: web_widget.website_token },
          as: :json

      expect(response).to have_http_status(:success)
      json_response = response.parsed_body
      expect(json_response['payload'].pluck('id')).to include(message.id)
      expect(json_response['meta']).to have_key('contact_last_seen_at')
    end

    it 'returns not found for another contact conversation' do
      other_contact_inbox = create(:contact_inbox, inbox: web_widget.inbox)
      other_conversation = create(:conversation, account: account, inbox: web_widget.inbox,
                                                 contact: other_contact_inbox.contact, contact_inbox: other_contact_inbox)

      get "/api/v2/widget/conversations/#{other_conversation.display_id}/messages",
          headers: headers,
          params: { website_token: web_widget.website_token },
          as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST messages' do
    it 'creates an incoming message on the routed conversation' do
      post "/api/v2/widget/conversations/#{conversation.display_id}/messages",
           headers: headers,
           params: { website_token: web_widget.website_token, message: { content: 'hello world', echo_id: 'echo-1' } },
           as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['content']).to eq('hello world')
      expect(conversation.messages.incoming.last.content).to eq('hello world')
      expect(conversation.messages.incoming.last.sender).to eq(contact)
    end
  end

  describe 'PATCH messages/:id' do
    let!(:csat_message) { create(:message, conversation: conversation, account: account, content_type: 'input_csat', message_type: :template) }

    it 'updates submitted values on the message' do
      patch "/api/v2/widget/conversations/#{conversation.display_id}/messages/#{csat_message.id}",
            headers: headers,
            params: {
              website_token: web_widget.website_token,
              message: { submitted_values: { csat_survey_response: { rating: 5 } } }
            },
            as: :json

      expect(response).to have_http_status(:success)
      expect(csat_message.reload.content_attributes[:submitted_values][:csat_survey_response][:rating]).to eq(5)
    end
  end
end
