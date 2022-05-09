require 'rails_helper'

RSpec.describe '/api/v1/widget/messages', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account, email: nil) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:conversation) { create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { ::Widget::TokenService.new(payload: payload).generate_token }

  before do |example|
    2.times.each { create(:message, account: account, inbox: web_widget.inbox, conversation: conversation) } unless example.metadata[:skip_before]
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
        # 2 messages created + 2 messages by the email hook
        expect(json_response['payload'].length).to eq(4)
        expect(json_response['meta']).not_to be_empty
      end

      it 'returns empty messages', :skip_before do
        get api_v1_widget_messages_url,
            params: { website_token: web_widget.website_token },
            headers: { 'X-Auth-Token' => token },
            as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['payload'].length).to eq(0)
      end
    end
  end

  describe 'POST /api/v1/widget/messages' do
    context 'when post request is made' do
      it 'creates message in conversation' do
        conversation.destroy! # Test all params
        message_params = { content: 'hello world', timestamp: Time.current }
        post api_v1_widget_messages_url,
             params: { website_token: web_widget.website_token, message: message_params },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['content']).to eq(message_params[:content])
      end

      it 'does not create the message' do
        conversation.destroy! # Test all params
        message_params = { content: "#{'h' * 150 * 1000}a", timestamp: Time.current }
        post api_v1_widget_messages_url,
             params: { website_token: web_widget.website_token, message: message_params },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)

        expect(json_response['message']).to eq('Content is too long (maximum is 150000 characters)')
      end

      it 'creates attachment message in conversation' do
        file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')
        message_params = { content: 'hello world', timestamp: Time.current, attachments: [file] }
        post api_v1_widget_messages_url,
             params: { website_token: web_widget.website_token, message: message_params },
             headers: { 'X-Auth-Token' => token }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['content']).to eq(message_params[:content])

        expect(conversation.messages.last.attachments.first.file.present?).to eq(true)
        expect(conversation.messages.last.attachments.first.file_type).to eq('image')
      end

      it 'does not reopen conversation when conversation is muted' do
        conversation.mute!

        message_params = { content: 'hello world', timestamp: Time.current }
        post api_v1_widget_messages_url,
             params: { website_token: web_widget.website_token, message: message_params },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.resolved?).to eq(true)
      end

      it 'does not create resolved activity messages when snoozed conversation is opened' do
        conversation.snoozed!

        message_params = { content: 'hello world', timestamp: Time.current }
        post api_v1_widget_messages_url,
             params: { website_token: web_widget.website_token, message: message_params },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(Conversations::ActivityMessageJob).not_to have_been_enqueued.at_least(:once).with(
          conversation,
          {
            account_id: conversation.account_id,
            inbox_id: conversation.inbox_id,
            message_type: :activity,
            content: "Conversation was resolved by #{contact.name}"
          }
        )
        expect(response).to have_http_status(:success)
        expect(conversation.reload.open?).to eq(true)
      end
    end
  end

  describe 'PUT /api/v1/widget/messages' do
    context 'when put request is made with non existing email' do
      it 'updates message in conversation and creates a new contact' do
        message = create(:message, content_type: 'input_email', account: account, inbox: web_widget.inbox, conversation: conversation)
        email = Faker::Internet.email
        contact_params = { email: email }
        put api_v1_widget_message_url(message.id),
            params: { website_token: web_widget.website_token, contact: contact_params },
            headers: { 'X-Auth-Token' => token },
            as: :json

        expect(response).to have_http_status(:success)
        message.reload
        expect(message.submitted_email).to eq(email)
        expect(message.conversation.contact.email).to eq(email)
      end
    end

    context 'when put request is made with invalid email' do
      it 'rescues the error' do
        message = create(:message, account: account, content_type: 'input_email', inbox: web_widget.inbox, conversation: conversation)
        contact_params = { email: nil }
        put api_v1_widget_message_url(message.id),
            params: { website_token: web_widget.website_token, contact: contact_params },
            headers: { 'X-Auth-Token' => token },
            as: :json

        expect(response).to have_http_status(:success)
      end
    end

    context 'when put request is made with existing email' do
      it 'updates message in conversation and deletes the current contact' do
        message = create(:message, account: account, content_type: 'input_email', inbox: web_widget.inbox, conversation: conversation)
        email = Faker::Internet.email
        create(:contact, account: account, email: email)
        contact_params = { email: email }
        put api_v1_widget_message_url(message.id),
            params: { website_token: web_widget.website_token, contact: contact_params },
            headers: { 'X-Auth-Token' => token },
            as: :json

        expect(response).to have_http_status(:success)
        message.reload
        expect { contact.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'ignores the casing of email, updates message in conversation and deletes the current contact' do
        message = create(:message, content_type: 'input_email', account: account, inbox: web_widget.inbox, conversation: conversation)
        email = Faker::Internet.email
        create(:contact, account: account, email: email)
        contact_params = { email: email.upcase }
        put api_v1_widget_message_url(message.id),
            params: { website_token: web_widget.website_token, contact: contact_params },
            headers: { 'X-Auth-Token' => token },
            as: :json

        expect(response).to have_http_status(:success)
        message.reload
        expect { contact.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
