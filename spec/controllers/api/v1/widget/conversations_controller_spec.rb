require 'rails_helper'

RSpec.describe '/api/v1/widget/conversations/toggle_typing', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account, email: nil) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:second_session) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let!(:conversation) { create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox) }
  let(:payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { Widget::TokenService.new(payload: payload).generate_token }
  let(:token_without_conversation) do
    Widget::TokenService.new(payload: { source_id: second_session.source_id, inbox_id: web_widget.inbox.id }).generate_token
  end

  def conversation_params
    {
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
    }
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
        json_response = response.parsed_body

        expect(json_response['id']).to eq(conversation.display_id)
        expect(json_response['status']).to eq(conversation.status)
      end
    end

    context 'with a conversation but invalid source id' do
      it 'returns the correct conversation params' do
        allow(Rails.configuration.dispatcher).to receive(:dispatch)

        payload = { source_id: 'invalid source id', inbox_id: web_widget.inbox.id }
        token = Widget::TokenService.new(payload: payload).generate_token
        get '/api/v1/widget/conversations',
            headers: { 'X-Auth-Token' => token },
            params: { website_token: web_widget.website_token },
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /api/v1/widget/conversations/list' do
    let!(:older_conversation) do
      create(:conversation, contact: contact, account: account, inbox: web_widget.inbox, contact_inbox: contact_inbox,
                            status: :resolved, last_activity_at: 2.days.ago)
    end

    before do
      allow(Rails.configuration.dispatcher).to receive(:dispatch)
      create(:message, account: account, inbox: web_widget.inbox, conversation: conversation, content: 'visitor question')
      create(:message, account: account, inbox: web_widget.inbox, conversation: conversation, content: 'agent reply', message_type: :outgoing)
      create(:message, account: account, inbox: web_widget.inbox, conversation: conversation, content: 'private note',
                       message_type: :outgoing, private: true)
      create(:message, account: account, inbox: web_widget.inbox, conversation: older_conversation, content: 'old reply', message_type: :outgoing)
      # Message creation bumps last_activity_at, so pin the order after the messages exist.
      older_conversation.update!(contact_last_seen_at: Time.current, last_activity_at: 2.days.ago)
    end

    it 'lists only the visitor conversations, most recently active first' do
      create(:conversation, account: account, inbox: web_widget.inbox)

      get '/api/v1/widget/conversations/list',
          headers: { 'X-Auth-Token' => token },
          params: { website_token: web_widget.website_token },
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload'].pluck('id')).to eq([conversation.display_id, older_conversation.display_id])
      expect(response.parsed_body['payload'].pluck('status')).to eq(%w[open resolved])
      expect(response.parsed_body['meta']['has_next_page']).to be(false)
    end

    it 'includes the unread count and the last visible message of each conversation' do
      get '/api/v1/widget/conversations/list',
          headers: { 'X-Auth-Token' => token },
          params: { website_token: web_widget.website_token },
          as: :json

      latest, older = response.parsed_body['payload']
      expect(latest['unread_count']).to eq(1)
      expect(latest['last_message']['content']).to eq('agent reply')
      expect(older['unread_count']).to eq(0)
      expect(older['last_message']['content']).to eq('old reply')
    end

    it 'counts the conversations with unread messages across all pages' do
      stub_const('Api::V1::Widget::ConversationsController::RESULTS_PER_PAGE', 1)

      get '/api/v1/widget/conversations/list',
          headers: { 'X-Auth-Token' => token },
          params: { website_token: web_widget.website_token, page: 2 },
          as: :json

      expect(response.parsed_body['meta']['unread_count']).to eq(1)
    end

    it 'paginates the list' do
      stub_const('Api::V1::Widget::ConversationsController::RESULTS_PER_PAGE', 1)

      get '/api/v1/widget/conversations/list',
          headers: { 'X-Auth-Token' => token },
          params: { website_token: web_widget.website_token, page: 2 },
          as: :json

      expect(response.parsed_body['payload'].pluck('id')).to eq([older_conversation.display_id])
      expect(response.parsed_body['meta']['has_next_page']).to be(false)
    end

    it 'returns an empty list for a session without conversations' do
      get '/api/v1/widget/conversations/list',
          headers: { 'X-Auth-Token' => token_without_conversation },
          params: { website_token: web_widget.website_token },
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']).to be_empty
    end
  end

  describe 'POST /api/v1/widget/conversations' do
    it 'creates a conversation with correct details' do
      post '/api/v1/widget/conversations',
           headers: { 'X-Auth-Token' => token },
           params: conversation_params,
           as: :json

      expect(response).to have_http_status(:success)
      json_response = response.parsed_body
      expect(json_response['id']).not_to be_nil
      expect(json_response['contact']['email']).to eq 'contact-email@chatwoot.com'
      expect(json_response['contact']['phone_number']).to eq '+919745313456'
      expect(json_response['contact']['name']).to eq 'contact-name'
    end

    it 'creates a conversation with correct message and custom attributes' do
      post '/api/v1/widget/conversations',
           headers: { 'X-Auth-Token' => token },
           params: conversation_params,
           as: :json

      expect(response).to have_http_status(:success)
      json_response = response.parsed_body
      expect(json_response['custom_attributes']['order_id']).to eq '12345'
      expect(json_response['messages'][0]['content']).to eq 'This is a test message'
      expect(json_response['messages'][0]['message_type']).to eq 0
    end

    it 'create a conversation with a name and without an email' do
      post '/api/v1/widget/conversations',
           headers: { 'X-Auth-Token' => token },
           params: {
             website_token: web_widget.website_token,
             contact: {
               name: 'alphy'
             },
             message: {
               content: 'This is a test message'
             }
           },
           as: :json

      expect(response).to have_http_status(:success)
      json_response = response.parsed_body
      expect(json_response['id']).not_to be_nil
      expect(json_response['contact']['email']).to be_nil
      expect(json_response['contact']['name']).to eq 'alphy'
      expect(json_response['messages'][0]['content']).to eq 'This is a test message'
    end

    it 'does not update the name if the contact already exist' do
      existing_contact = create(:contact, account: account, email: 'contact-email@chatwoot.com')

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
      json_response = response.parsed_body
      expect(json_response['id']).not_to be_nil
      expect(json_response['contact']['email']).to eq existing_contact.email
      expect(json_response['contact']['name']).not_to eq 'contact-name'
      expect(json_response['contact']['phone_number']).to eq '+919745313456'
      expect(json_response['custom_attributes']['order_id']).to eq '12345'
      expect(json_response['messages'][0]['content']).to eq 'This is a test message'
    end

    it 'saves contact custom attributes on the widget contact' do
      post '/api/v1/widget/conversations',
           headers: { 'X-Auth-Token' => token },
           params: {
             website_token: web_widget.website_token,
             contact: {
               name: 'contact-name',
               email: 'contact-email@chatwoot.com',
               custom_attributes: { cpf: '123.456.789-09' }
             },
             message: {
               content: 'This is a test message'
             }
           },
           as: :json

      expect(response).to have_http_status(:success)
      expect(contact.reload.custom_attributes['cpf']).to eq('123.456.789-09')
    end

    it 'saves contact custom attributes on the surviving contact when merged into an existing contact' do
      existing_contact = create(:contact, account: account, email: 'contact-email@chatwoot.com', custom_attributes: { 'cpf' => 'old-value' })

      post '/api/v1/widget/conversations',
           headers: { 'X-Auth-Token' => token },
           params: {
             website_token: web_widget.website_token,
             contact: {
               name: 'contact-name',
               email: existing_contact.email,
               custom_attributes: { cpf: '123.456.789-09' }
             },
             message: {
               content: 'This is a test message'
             }
           },
           as: :json

      expect(response).to have_http_status(:success)
      # the widget contact is merged into the existing contact; the freshly
      # submitted value must land on the surviving contact and win over stale data
      expect(Contact.exists?(contact.id)).to be(false)
      expect(existing_contact.reload.custom_attributes['cpf']).to eq('123.456.789-09')
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
      json_response = response.parsed_body
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
        current_time = DateTime.now.utc
        allow(DateTime).to receive(:now).and_return(current_time)

        allow(Rails.configuration.dispatcher).to receive(:dispatch)
        expect(conversation.contact_last_seen_at).to be_nil
        expect(Conversations::UpdateMessageStatusJob).to receive(:perform_later).with(conversation.id, current_time)

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
        contact.update(email: 'test@test.com')
        mailer = double
        allow(ConversationReplyMailer).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:conversation_transcript)

        post '/api/v1/widget/conversations/transcript',
             headers: { 'X-Auth-Token' => token },
             params: { website_token: web_widget.website_token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(mailer).to have_received(:conversation_transcript).with(conversation, 'test@test.com')
        contact.update(email: nil)
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
            content: "Conversation was resolved by #{contact.name}",
            content_attributes: { activity: { type: 'conversation_status_changed', status: 'resolved' } }
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

  describe 'POST /api/v1/widget/conversations/set_custom_attributes' do
    let(:params) { { website_token: web_widget.website_token, custom_attributes: { 'product_name': 'Chatwoot' } } }

    context 'with invalid website token' do
      it 'returns unauthorized' do
        post '/api/v1/widget/conversations/set_custom_attributes', params: { website_token: '' }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with correct website token' do
      it 'sets the values when provided' do
        post '/api/v1/widget/conversations/set_custom_attributes',
             headers: { 'X-Auth-Token' => token },
             params: params,
             as: :json

        expect(response).to have_http_status(:success)
        conversation.reload
        # conversation custom attributes should have "product_name" key with value "Chatwoot"
        expect(conversation.custom_attributes).to include('product_name' => 'Chatwoot')
      end
    end
  end

  describe 'POST /api/v1/widget/conversations/destroy_custom_attributes' do
    let(:params) { { website_token: web_widget.website_token, custom_attribute: ['product_name'] } }

    context 'with invalid website token' do
      it 'returns unauthorized' do
        post '/api/v1/widget/conversations/destroy_custom_attributes', params: { website_token: '' }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with correct website token' do
      it 'sets the values when provided' do
        # ensure conversation has the attribute
        conversation.custom_attributes = { 'product_name': 'Chatwoot' }
        conversation.save!
        expect(conversation.custom_attributes).to include('product_name' => 'Chatwoot')

        post '/api/v1/widget/conversations/destroy_custom_attributes',
             headers: { 'X-Auth-Token' => token },
             params: params,
             as: :json

        expect(response).to have_http_status(:success)
        conversation.reload
        # conversation custom attributes should not have "product_name" key with value "Chatwoot"
        expect(conversation.custom_attributes).not_to include('product_name' => 'Chatwoot')
      end
    end
  end
end
