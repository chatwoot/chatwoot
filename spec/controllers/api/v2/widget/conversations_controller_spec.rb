require 'rails_helper'

RSpec.describe '/api/v2/widget/conversations', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account, email: nil) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { Widget::TokenService.new(payload: payload).generate_token }
  let(:headers) { { 'X-Auth-Token' => token } }

  before do
    allow(Rails.configuration.dispatcher).to receive(:dispatch)
  end

  describe 'GET /api/v2/widget/conversations' do
    let!(:conversation) do
      create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox)
    end
    let!(:ai_conversation) do
      create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox,
                            additional_attributes: { 'widget_section' => 'ai' })
    end

    it 'returns the human-section conversations by default' do
      get '/api/v2/widget/conversations',
          headers: headers,
          params: { website_token: web_widget.website_token },
          as: :json

      expect(response).to have_http_status(:success)
      json_response = response.parsed_body
      expect(json_response['payload'].pluck('id')).to eq([conversation.display_id])
      expect(json_response['payload'].first['widget_section']).to eq('human')
      expect(json_response['meta']['has_next_page']).to be(false)
    end

    it 'splits active and resolved conversations by the status filter' do
      resolved = create(:conversation, contact: contact, account: account, inbox: web_widget.inbox,
                                       contact_inbox: contact_inbox, status: :resolved)

      get '/api/v2/widget/conversations',
          headers: headers,
          params: { website_token: web_widget.website_token, status: 'active' },
          as: :json
      expect(response.parsed_body['payload'].pluck('id')).to eq([conversation.display_id])

      get '/api/v2/widget/conversations',
          headers: headers,
          params: { website_token: web_widget.website_token, status: 'resolved' },
          as: :json
      expect(response.parsed_body['payload'].pluck('id')).to eq([resolved.display_id])
    end

    it 'returns AI conversations when section is ai' do
      get '/api/v2/widget/conversations',
          headers: headers,
          params: { website_token: web_widget.website_token, section: 'ai' },
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload'].pluck('id')).to eq([ai_conversation.display_id])
    end

    it 'rejects a token minted for another inbox' do
      other_widget = create(:channel_widget, account: account)
      other_token = Widget::TokenService.new(payload: { source_id: contact_inbox.source_id, inbox_id: other_widget.inbox.id }).generate_token

      get '/api/v2/widget/conversations',
          headers: { 'X-Auth-Token' => other_token },
          params: { website_token: web_widget.website_token },
          as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v2/widget/conversations' do
    let(:params) do
      {
        website_token: web_widget.website_token,
        contact: { name: 'contact-name', email: 'contact-email@chatwoot.com' },
        message: { content: 'This is a test message' }
      }
    end

    it 'creates a conversation with the first message' do
      post '/api/v2/widget/conversations', headers: headers, params: params, as: :json

      expect(response).to have_http_status(:success)
      json_response = response.parsed_body
      expect(json_response['widget_section']).to eq('human')
      expect(json_response['messages'].first['content']).to eq('This is a test message')
      expect(contact.reload.email).to eq('contact-email@chatwoot.com')
    end

    it 'allows multiple conversations for the same contact' do
      create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox)

      post '/api/v2/widget/conversations', headers: headers, params: params, as: :json

      expect(response).to have_http_status(:success)
      expect(contact.conversations.count).to eq(2)
    end

    it 'reuses the existing conversation when the inbox is locked to a single conversation' do
      web_widget.inbox.update!(lock_to_single_conversation: true)
      existing = create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox)

      post '/api/v2/widget/conversations', headers: headers, params: params, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['id']).to eq(existing.display_id)
    end

    it 'rejects the ai section when no assistant is connected' do
      post '/api/v2/widget/conversations', headers: headers, params: params.merge(section: 'ai'), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v2/widget/conversations/:display_id/resolve' do
    let!(:conversation) do
      create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox)
    end

    it 'resolves the conversation when the feature is enabled' do
      post "/api/v2/widget/conversations/#{conversation.display_id}/resolve",
           headers: headers,
           params: { website_token: web_widget.website_token },
           as: :json

      expect(response).to have_http_status(:success)
      expect(conversation.reload.status).to eq('resolved')
    end

    it 'is forbidden when end conversation is disabled on the widget' do
      web_widget.end_conversation = false
      web_widget.save!

      post "/api/v2/widget/conversations/#{conversation.display_id}/resolve",
           headers: headers,
           params: { website_token: web_widget.website_token },
           as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v2/widget/conversations/:display_id/update_last_seen' do
    let!(:conversation) do
      create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox)
    end

    it 'updates the contact last seen timestamp' do
      post "/api/v2/widget/conversations/#{conversation.display_id}/update_last_seen",
           headers: headers,
           params: { website_token: web_widget.website_token },
           as: :json

      expect(response).to have_http_status(:success)
      expect(conversation.reload.contact_last_seen_at).to be_present
    end
  end

  describe 'GET /api/v2/widget/conversations/:display_id' do
    it 'returns not found for a conversation of another contact' do
      other_contact_inbox = create(:contact_inbox, inbox: web_widget.inbox)
      other_conversation = create(:conversation, account: account, inbox: web_widget.inbox,
                                                 contact: other_contact_inbox.contact, contact_inbox: other_contact_inbox)

      get "/api/v2/widget/conversations/#{other_conversation.display_id}",
          headers: headers,
          params: { website_token: web_widget.website_token },
          as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
