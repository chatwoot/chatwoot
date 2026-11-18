require 'rails_helper'

# A visitor on a public channel (the website widget, the API channel's public API) types an email or
# a phone number that already belongs to another contact of the account. Without proof of identity
# the session must stay on the visitor's own contact: joining it to the existing one hands the
# visitor that contact's identity, its conversations and whatever an agent bot does in its name.
RSpec.describe 'Unproven contact merge on public channels', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account, hmac_mandatory: false) }
  let(:visitor) { create(:contact, account: account, email: nil, phone_number: nil, name: 'visitor') }
  let(:visitor_session) { create(:contact_inbox, contact: visitor, inbox: web_widget.inbox) }
  let(:token) do
    Widget::TokenService.new(payload: { source_id: visitor_session.source_id, inbox_id: web_widget.inbox.id }).generate_token
  end
  let(:headers) { { 'X-Auth-Token' => token } }
  let(:api_channel) { create(:channel_api, account: account) }
  let(:api_inbox) { api_channel.inbox }
  let!(:customer) do
    create(:contact, account: account, name: 'Customer', email: 'customer@example.com', phone_number: '+5511999990000')
  end
  let!(:customer_conversation) { create(:conversation, account: account, inbox: api_inbox, contact: customer) }

  shared_examples 'a session that keeps its own contact' do
    it 'does not join the session to the existing contact' do
      expect(visitor_session.reload.contact_id).to eq(visitor.id)
      expect(Contact.exists?(visitor.id)).to be(true)
      expect(customer_conversation.reload.contact_id).to eq(customer.id)
      expect(customer.reload.contact_inboxes.where(inbox: web_widget.inbox)).to be_empty
    end
  end

  describe 'PATCH /api/v1/widget/contact without an identifier' do
    context 'with the phone number of a contact created elsewhere' do
      before do
        patch '/api/v1/widget/contact', params: { website_token: web_widget.website_token, phone_number: customer.phone_number },
                                        headers: headers, as: :json
      end

      it_behaves_like 'a session that keeps its own contact'

      it 'keeps the typed value as an unverified claim of the visitor' do
        expect(response).to have_http_status(:success)
        expect(visitor.reload.phone_number).to be_nil
        expect(visitor.additional_attributes['claimed_phone_number']).to eq(customer.phone_number)
      end
    end

    context 'with the email of an existing contact' do
      before do
        patch '/api/v1/widget/contact', params: { website_token: web_widget.website_token, email: 'CUSTOMER@example.com' },
                                        headers: headers, as: :json
      end

      it_behaves_like 'a session that keeps its own contact'

      it 'keeps the typed value as an unverified claim of the visitor' do
        expect(visitor.reload.email).to be_nil
        expect(visitor.additional_attributes['claimed_email']).to eq('CUSTOMER@example.com')
      end
    end

    context 'with the email the visitor already has' do
      it 'records no claim' do
        visitor.update!(email: 'visitor@example.com')
        patch '/api/v1/widget/contact', params: { website_token: web_widget.website_token, email: 'visitor@example.com' },
                                        headers: headers, as: :json

        expect(visitor.reload.additional_attributes).not_to have_key('claimed_email')
      end
    end

    context 'with an email nobody has' do
      it 'still saves it on the visitor' do
        patch '/api/v1/widget/contact', params: { website_token: web_widget.website_token, email: 'new@example.com' },
                                        headers: headers, as: :json

        expect(visitor.reload.email).to eq('new@example.com')
        expect(visitor.additional_attributes).not_to have_key('claimed_email')
      end
    end
  end

  describe 'additional attributes the system reads as its own' do
    before do
      visitor.update!(additional_attributes: { 'external' => { 'leadsquared_id' => 'visitor-lead' } })
    end

    it 'ignores claims and CRM ids sent by the visitor and keeps the rest' do
      patch '/api/v1/widget/contact', params: {
        website_token: web_widget.website_token,
        additional_attributes: { city: 'Recife', claimed_email: 'customer@example.com', external: { leadsquared_id: 'customer-lead' } }
      }, headers: headers, as: :json

      expect(response).to have_http_status(:success)
      attributes = visitor.reload.additional_attributes
      expect(attributes['city']).to eq('Recife')
      expect(attributes).not_to have_key('claimed_email')
      expect(attributes['external']).to eq('leadsquared_id' => 'visitor-lead')
    end

    it 'ignores them on setUser too' do
      patch '/api/v1/widget/contact/set_user', params: {
        website_token: web_widget.website_token, identifier: 'visitor-on-site',
        additional_attributes: { claimed_phone_number: '+5511988887777' }
      }, headers: headers, as: :json

      expect(response).to have_http_status(:success)
      expect(visitor.reload.additional_attributes).not_to have_key('claimed_phone_number')
    end
  end

  describe 'PATCH /api/v1/widget/contact/set_user' do
    let(:identifier) { 'visitor-on-the-site' }

    context 'without an identifier hash on an inbox where HMAC is optional' do
      before do
        patch '/api/v1/widget/contact/set_user',
              params: { website_token: web_widget.website_token, identifier: identifier, email: customer.email },
              headers: headers, as: :json
      end

      it_behaves_like 'a session that keeps its own contact'
    end

    context 'with a valid identifier hash' do
      let(:identifier_hash) { OpenSSL::HMAC.hexdigest('sha256', web_widget.hmac_token, identifier) }

      # The hash signs the identifier and nothing else: a signed-in visitor can send their own
      # identifier and hash next to someone else's email.
      context 'with the email of a contact that lacks that identifier' do
        before do
          patch '/api/v1/widget/contact/set_user',
                params: { website_token: web_widget.website_token, identifier: identifier, identifier_hash: identifier_hash,
                          email: customer.email },
                headers: headers, as: :json
        end

        it_behaves_like 'a session that keeps its own contact'

        it 'still identifies the visitor by the signed identifier' do
          expect(response).to have_http_status(:success)
          expect(visitor.reload.identifier).to eq(identifier)
          expect(visitor.additional_attributes['claimed_email']).to eq(customer.email)
        end
      end

      it 'joins the contact that holds the signed identifier' do
        customer.update!(identifier: identifier)
        patch '/api/v1/widget/contact/set_user',
              params: { website_token: web_widget.website_token, identifier: identifier, identifier_hash: identifier_hash,
                        email: customer.email },
              headers: headers, as: :json

        expect(response).to have_http_status(:success)
        expect(visitor_session.reload.contact_id).to eq(customer.id)
      end
    end
  end

  describe 'POST /api/v1/widget/conversations (pre-chat form)' do
    before do
      post '/api/v1/widget/conversations',
           params: { website_token: web_widget.website_token,
                     contact: { name: 'Someone', email: customer.email, phone_number: customer.phone_number },
                     message: { content: 'hi' } },
           headers: headers, as: :json
    end

    it_behaves_like 'a session that keeps its own contact'

    it 'opens the conversation on the visitor and does not ask again for the email it was given' do
      conversation = visitor_session.reload.conversations.last
      expect(conversation.contact_id).to eq(visitor.id)
      expect(conversation.messages.where(content_type: 'input_email')).to be_empty
    end
  end

  describe 'PUT /api/v1/widget/messages/:id (email collect card)' do
    let!(:conversation) { create(:conversation, account: account, inbox: web_widget.inbox, contact: visitor, contact_inbox: visitor_session) }
    let!(:email_card) { create(:message, account: account, inbox: web_widget.inbox, conversation: conversation, content_type: 'input_email') }

    before do
      put api_v1_widget_message_url(email_card.id), params: { website_token: web_widget.website_token, contact: { email: customer.email } },
                                                    headers: headers, as: :json
    end

    it_behaves_like 'a session that keeps its own contact'

    it 'records what the visitor submitted on the card' do
      expect(response).to have_http_status(:success)
      expect(email_card.reload.submitted_email).to eq(customer.email)
      expect(conversation.reload.contact_id).to eq(visitor.id)
    end
  end

  describe 'public API of an API channel' do
    it 'does not hand a new session the existing contact found by phone number' do
      post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts", params: { phone_number: customer.phone_number }

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['id']).not_to eq(customer.id)
      expect(response.parsed_body['email']).to be_nil
      expect(response.parsed_body['name']).not_to eq('Customer')
      expect(response.parsed_body['phone_number']).to be_nil
    end

    it 'still finds the contact that holds a signed identifier' do
      customer.update!(identifier: 'customer-42')
      identifier_hash = OpenSSL::HMAC.hexdigest('sha256', api_channel.hmac_token, 'customer-42')
      post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts",
           params: { identifier: 'customer-42', identifier_hash: identifier_hash, email: 'someone.else@example.com' }

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['id']).to eq(customer.id)
    end

    it 'creates the new session with the taken email kept as a claim' do
      post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts", params: { email: customer.email, name: 'Someone' }

      expect(response).to have_http_status(:success)
      created = account.contacts.find(response.parsed_body['id'])
      expect(created.email).to be_nil
      expect(created.additional_attributes['claimed_email']).to eq(customer.email)
    end

    it 'does not join an existing session to the contact found by email' do
      session = create(:contact_inbox, contact: visitor, inbox: api_inbox)
      patch "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{session.source_id}", params: { email: customer.email }

      expect(response).to have_http_status(:success)
      expect(session.reload.contact_id).to eq(visitor.id)
      expect(customer_conversation.reload.contact_id).to eq(customer.id)
    end
  end

  # A phone number typed on a public channel proves nothing even when nobody holds it yet: kept on
  # the contact, it reaches an agent bot's tools as the visitor's verified phone (and through them
  # whatever an outside system keeps for that number), and the real owner writing in later through
  # WhatsApp lands on the visitor's contact.
  describe 'a phone number nobody holds yet' do
    let(:free_phone) { '+5511977776666' }

    it 'stays an unverified claim on the widget contact update' do
      patch '/api/v1/widget/contact', params: { website_token: web_widget.website_token, phone_number: free_phone },
                                      headers: headers, as: :json

      expect(response).to have_http_status(:success)
      expect(visitor.reload.phone_number).to be_nil
      expect(visitor.additional_attributes['claimed_phone_number']).to eq(free_phone)
    end

    it 'stays an unverified claim on the pre-chat form' do
      post '/api/v1/widget/conversations',
           params: { website_token: web_widget.website_token, contact: { name: 'Someone', phone_number: free_phone },
                     message: { content: 'hi' } },
           headers: headers, as: :json

      expect(response).to have_http_status(:success)
      expect(visitor.reload.phone_number).to be_nil
      expect(visitor.additional_attributes['claimed_phone_number']).to eq(free_phone)
    end

    it 'stays an unverified claim on a new public API session' do
      post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts", params: { phone_number: free_phone }

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['phone_number']).to be_nil
      expect(account.contacts.find(response.parsed_body['id']).additional_attributes['claimed_phone_number']).to eq(free_phone)
    end

    it 'leaves the real owner arriving later through another channel on a contact of their own' do
      patch '/api/v1/widget/contact', params: { website_token: web_widget.website_token, phone_number: free_phone },
                                      headers: headers, as: :json

      owner_session = ContactInboxWithContactBuilder.new(
        inbox: api_inbox, source_id: SecureRandom.uuid, contact_attributes: { name: 'Owner', phone_number: free_phone }
      ).perform

      expect(owner_session.contact_id).not_to eq(visitor.id)
    end

    it 'records no claim for a value that is not a phone number' do
      patch '/api/v1/widget/contact', params: { website_token: web_widget.website_token, phone_number: '12345' },
                                      headers: headers, as: :json

      expect(visitor.reload.additional_attributes).not_to have_key('claimed_phone_number')
    end

    it 'records no claim for the phone number the contact already has' do
      visitor.update!(phone_number: free_phone)
      patch '/api/v1/widget/contact', params: { website_token: web_widget.website_token, phone_number: free_phone },
                                      headers: headers, as: :json

      expect(visitor.reload.phone_number).to eq(free_phone)
      expect(visitor.additional_attributes).not_to have_key('claimed_phone_number')
    end
  end

  # WhatsApp contacts carry "<lid>@lid" (and group JIDs) as their identifier. On an inbox where HMAC
  # is optional, an unsigned identifier finds its contact, so a visitor who knows someone's LID would
  # reach their WhatsApp contact. No site identifies its users that way.
  describe 'an identifier in the format WhatsApp uses' do
    let!(:whatsapp_contact) { create(:contact, account: account, identifier: '123456789012345@lid', phone_number: '+5511955554444') }

    %w[123456789012345@lid 5511955554444@s.whatsapp.net 120363000000000000@g.us].each do |identifier|
      it "is refused by setUser (#{identifier.split('@').last})" do
        patch '/api/v1/widget/contact/set_user',
              params: { website_token: web_widget.website_token, identifier: identifier }, headers: headers, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(visitor_session.reload.contact_id).to eq(visitor.id)
        expect(whatsapp_contact.reload.contact_inboxes.where(inbox: web_widget.inbox)).to be_empty
      end
    end

    it 'is refused by the widget contact update' do
      patch '/api/v1/widget/contact', params: { website_token: web_widget.website_token, identifier: whatsapp_contact.identifier },
                                      headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(visitor_session.reload.contact_id).to eq(visitor.id)
    end

    it 'is refused by setUser even with a valid hash' do
      identifier_hash = OpenSSL::HMAC.hexdigest('sha256', web_widget.hmac_token, whatsapp_contact.identifier)
      patch '/api/v1/widget/contact/set_user',
            params: { website_token: web_widget.website_token, identifier: whatsapp_contact.identifier, identifier_hash: identifier_hash },
            headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'is refused by the public API' do
      post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts", params: { identifier: whatsapp_contact.identifier }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(whatsapp_contact.reload.contact_inboxes.where(inbox: api_inbox)).to be_empty
    end
  end

  it 'answers 401, not 500, to a public API request without the hash an inbox requires' do
    api_channel.update!(hmac_mandatory: true)
    post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts", params: { identifier: 'customer-42' }

    expect(response).to have_http_status(:unauthorized)
  end

  # Upstream turns these into a private note that points the agent at the contact the visitor's
  # value belongs to (Conversations::UnverifiedContactNoteService).
  describe 'the unverified matches handed to upstream' do
    def identify(params)
      action = ContactIdentifyAction.new(contact: visitor, params: params)
      UnprovenContactMergeGuard.unproven { action.perform }
      action
    end

    it 'names the contact that holds the typed phone number' do
      action = identify(phone_number: customer.phone_number)

      expect(action.unverified_matches).to eq([{ key: :phone_number, value: customer.phone_number, contact: customer }])
    end

    it 'names nobody for a phone number no contact holds, and still keeps it as a claim' do
      action = identify(phone_number: '+5511988887777')

      expect(action.unverified_matches).to be_empty
      expect(visitor.reload.additional_attributes['claimed_phone_number']).to eq('+5511988887777')
    end
  end
end
