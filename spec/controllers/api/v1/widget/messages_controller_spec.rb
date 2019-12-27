require 'rails_helper'

RSpec.describe '/api/v1/widget/messages', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, contact: contact, account: account, inbox: web_widget.inbox) }
  let(:payload) { { contact_id: contact.id, inbox_id: web_widget.inbox.id } }
  let(:token) { ::Widget::TokenService.new(payload: payload).generate_token }

  before do
    create(:contact_inbox, contact: contact, inbox: web_widget.inbox)
    2.times.each { create(:message, account: account, inbox: web_widget.inbox, conversation: conversation) }
  end

  describe 'GET /api/v1/widget/messages' do
    context 'when get request is made' do
      it 'returns messages in conversation' do
        get api_v1_widget_messages_url,
            params: { website_token: web_widget.website_token },
            headers: { 'X-Auth-Token' => token },
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)

        # 2 messages created + 3 messages by the template hook
        expect(json_response.length).to eq(5)
      end
    end
  end

  describe 'POST /api/v1/widget/messages' do
    context 'when post request is made' do
      it 'creates message in conversation' do
        message_params = { content: 'hello world' }
        post api_v1_widget_messages_url,
             params: { website_token: web_widget.website_token, message: message_params },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['content']).to eq(message_params[:content])
      end
    end
  end

  describe 'PUT /api/v1/widget/messages' do
    context 'when put request is made with non existing email' do
      it 'updates message in conversation and return token for new contact' do
        message = create(:message, account: account, inbox: web_widget.inbox, conversation: conversation)
        email = Faker::Internet.email
        contact_params = { email: email }
        put api_v1_widget_message_url(message.id),
            params: { website_token: web_widget.website_token, contact: contact_params },
            headers: { 'X-Auth-Token' => token },
            as: :json

        expect(response).to have_http_status(:success)
        message.reload
        json_response = JSON.parse(response.body)
        expect(json_response['token']).to eq(token)
        expect(message.input_submitted_email).to eq(email)
      end
    end

    context 'when put request is made with existing email' do
      it 'updates message in conversation and return token for existing contact' do
        message = create(:message, account: account, inbox: web_widget.inbox, conversation: conversation)
        email = Faker::Internet.email
        existing_contact = create(:contact, account: account, email: email)
        existing_token = ::Widget::TokenService.new(payload: { contact_id: existing_contact.id, inbox_id: web_widget.inbox.id }).generate_token
        contact_params = { email: email }
        put api_v1_widget_message_url(message.id),
            params: { website_token: web_widget.website_token, contact: contact_params },
            headers: { 'X-Auth-Token' => token },
            as: :json

        expect(response).to have_http_status(:success)
        message.reload
        json_response = JSON.parse(response.body)
        expect(json_response['token']).not_to eq(token)
        # ensure token generated is of the old contact with same email
        expect(json_response['token']).to eq(existing_token)
        expect { contact.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
