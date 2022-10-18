require 'rails_helper'

RSpec.describe '/api/v1/widget/conversations/toggle_typing', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account, email: nil) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:second_session) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let!(:conversation) { create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { ::Widget::TokenService.new(payload: payload).generate_token }
  let(:token_without_conversation) do
    ::Widget::TokenService.new(payload: { source_id: second_session.source_id, inbox_id: web_widget.inbox.id }).generate_token
  end

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

    context 'with a conversation but invalid source id' do
      it 'returns the correct conversation params' do
        allow(Rails.configuration.dispatcher).to receive(:dispatch)

        payload = { source_id: 'invalid source id', inbox_id: web_widget.inbox.id }
        token = ::Widget::TokenService.new(payload: payload).generate_token
        get '/api/v1/widget/conversations',
            headers: { 'X-Auth-Token' => token },
            params: { website_token: web_widget.website_token },
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/widget/conversations' do
    it 'creates a conversation' do
      post '/api/v1/widget/conversations',
           headers: { 'X-Auth-Token' => token },
           params: {
             website_token: web_widget.website_token,
             contact: {
               name: 'contact-name',
               email: 'contact-email@chatwoot.com',
               phone_number: '+919745313456'
             },
             message: {
               content: 'This is a test message'
             },
             custom_attributes: { order_id: '12345' }
           },
           as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['id']).not_to be_nil
      expect(json_response['contact']['email']).to eq 'contact-email@chatwoot.com'
      expect(json_response['contact']['phone_number']).to eq '+919745313456'
      expect(json_response['contact']['name']).to eq 'contact-name'
      expect(json_response['custom_attributes']['order_id']).to eq '12345'
      expect(json_response['messages'][0]['content']).to eq 'This is a test message'
    end

    it 'does not update the name if the contact already exist' do
      existing_contact = create(:contact, account: account)

      post '/api/v1/widget/conversations',
           headers: { 'X-Auth-Token' => token },
           params: {
             website_token: web_widget.website_token,
             contact: {
               name: 'contact-name',
               email: existing_contact.email,
               phone_number: '+919745313456'
             },
             message: {
               content: 'This is a test message'
             },
             custom_attributes: { order_id: '12345' }
           },
           as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['id']).not_to be_nil
      expect(json_response['contact']['email']).to eq existing_contact.email
      expect(json_response['contact']['name']).not_to eq 'contact-name'
      expect(json_response['contact']['phone_number']).to eq '+919745313456'
      expect(json_response['custom_attributes']['order_id']).to eq '12345'
      expect(json_response['messages'][0]['content']).to eq 'This is a test message'
    end

    it 'doesnt not add phone number if the invalid phone number is provided' do
      existing_contact = create(:contact, account: account)

      post '/api/v1/widget/conversations',
           headers: { 'X-Auth-Token' => token },
           params: {
             website_token: web_widget.website_token,
             contact: {
               name: 'contact-name-1',
               email: existing_contact.email,
               phone_number: '13456'
             },
             message: {
               content: 'This is a test message'
             }
           },
           as: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['contact']['phone_number']).to be_nil
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
        expect(conversation.contact_last_seen_at).to be_nil

        post '/api/v1/widget/conversations/update_last_seen',
             headers: { 'X-Auth-Token' => token },
             params: { website_token: web_widget.website_token },
             as: :json

        expect(response).to have_http_status(:success)

        expect(conversation.reload.contact_last_seen_at).not_to be_nil
      end
    end
  end

  describe 'POST /api/v1/widget/conversations/transcript' do
    context 'with a conversation' do
      it 'sends transcript email' do
        mailer = double
        allow(ConversationReplyMailer).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:conversation_transcript)

        post '/api/v1/widget/conversations/transcript',
             headers: { 'X-Auth-Token' => token },
             params: { website_token: web_widget.website_token, email: 'test@test.com' },
             as: :json

        expect(response).to have_http_status(:success)
        expect(mailer).to have_received(:conversation_transcript).with(conversation, 'test@test.com')
      end
    end
  end

  describe 'GET /api/v1/widget/conversations/toggle_status' do
    context 'when user end conversation from widget' do
      it 'resolves the conversation' do
        expect(conversation.open?).to be true

        get '/api/v1/widget/conversations/toggle_status',
            headers: { 'X-Auth-Token' => token },
            params: { website_token: web_widget.website_token },
            as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.resolved?).to be true
        expect(Conversations::ActivityMessageJob).to have_been_enqueued.at_least(:once).with(
          conversation,
          {
            account_id: conversation.account_id,
            inbox_id: conversation.inbox_id,
            message_type: :activity,
            content: "Conversation was resolved by #{contact.name}"
          }
        )
      end
    end

    context 'when end conversation is not permitted' do
      before do
        web_widget.end_conversation = false
        web_widget.save!
      end

      it 'returns action not permitted status' do
        expect(conversation.open?).to be true

        get '/api/v1/widget/conversations/toggle_status',
            headers: { 'X-Auth-Token' => token },
            params: { website_token: web_widget.website_token },
            as: :json

        expect(response).to have_http_status(:forbidden)
        expect(conversation.reload.resolved?).to be false
      end
    end

    context 'when a token without any conversation is used' do
      it 'returns not found status' do
        get '/api/v1/widget/conversations/toggle_status',
            headers: { 'X-Auth-Token' => token_without_conversation },
            params: { website_token: web_widget.website_token },
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
