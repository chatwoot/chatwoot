require 'rails_helper'

RSpec.describe '/api/v2/widget/conversations', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:token) do
    Widget::TokenService.new(payload: { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id }).generate_token
  end
  let(:headers) { { 'X-Auth-Token' => token } }
  let(:params) do
    {
      website_token: web_widget.website_token,
      message: { content: 'I need help' }
    }
  end

  before do
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
    create(:captain_inbox, captain_assistant: assistant, inbox: web_widget.inbox)
  end

  describe 'POST /api/v2/widget/conversations with a captain assistant' do
    it 'creates an ai-section conversation as pending so captain picks it up' do
      post '/api/v2/widget/conversations', headers: headers, params: params.merge(section: 'ai'), as: :json

      expect(response).to have_http_status(:success)
      json_response = response.parsed_body
      expect(json_response['widget_section']).to eq('ai')
      expect(json_response['status']).to eq('pending')
      expect(json_response['ai_state']).to eq('ai')
    end

    it 'keeps human-section conversations away from captain' do
      post '/api/v2/widget/conversations', headers: headers, params: params, as: :json

      expect(response).to have_http_status(:success)
      json_response = response.parsed_body
      expect(json_response['widget_section']).to eq('human')
      expect(json_response['status']).to eq('open')
      expect(json_response['ai_state']).to eq('human')
    end

    it 'reopens a resolved human conversation as open instead of pending' do
      post '/api/v2/widget/conversations', headers: headers, params: params, as: :json
      conversation = Conversation.find_by(display_id: response.parsed_body['id'])
      conversation.resolved!

      post "/api/v2/widget/conversations/#{conversation.display_id}/messages",
           headers: headers,
           params: { website_token: web_widget.website_token, message: { content: 'hello again' } },
           as: :json

      expect(response).to have_http_status(:success)
      expect(conversation.reload.status).to eq('open')
    end
  end
end
