require 'rails_helper'

RSpec.describe 'POST /api/v1/widget/contact/identify', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:widget_token) { Widget::TokenService.new(payload: { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id }).generate_token }
  let!(:signing_key) { create(:contact_identity_signing_key, inbox: web_widget.inbox) }
  let(:claims) { { identifier: 'user-1', name: 'Priya', email: 'priya@example.com', phone_number: '+919999888877' } }

  def identity_token(claims, secret: signing_key.secret, algorithm: 'HS256')
    JWT.encode(claims, secret, algorithm)
  end

  def identify(token, widget_token: self.widget_token)
    post '/api/v1/widget/contact/identify',
         params: { website_token: web_widget.website_token, identity_token: token },
         headers: { 'X-Auth-Token' => widget_token },
         as: :json
  end

  context 'with a valid token' do
    it 'identifies the contact and stores the signed details as verified' do
      identify(identity_token(claims))

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['id']).to eq(contact.id)
      expect(contact.reload).to have_attributes(identifier: 'user-1', name: 'Priya', email: 'priya@example.com', phone_number: '+919999888877')
      expect(contact.verified_attributes).to eq('name' => 'jwt', 'email' => 'jwt', 'phone_number' => 'jwt')
    end

    it 'marks the session as verified' do
      identify(identity_token(claims))

      expect(contact_inbox.reload.hmac_verified).to be(true)
    end

    it 'writes custom attributes as ordinary values' do
      contact.update!(custom_attributes: { plan: 'free', seats: 3 })

      identify(identity_token(claims.merge(custom_attributes: { plan: 'pro' })))

      expect(contact.reload.custom_attributes).to eq('plan' => 'pro', 'seats' => 3)
      expect(contact.verified_attributes.keys).to contain_exactly('name', 'email', 'phone_number')
    end

    it 'marks a value the contact already stores' do
      contact.update!(identifier: 'user-1', name: 'Priya', email: 'priya@example.com', phone_number: '+919999888877')

      identify(identity_token(claims))

      expect(response).to have_http_status(:success)
      expect(contact.reload.verified_attributes).to eq('name' => 'jwt', 'email' => 'jwt', 'phone_number' => 'jwt')
    end

    it 'replaces a verified value when a later token signs another one' do
      identify(identity_token(claims))
      identify(identity_token(claims.merge(email: 'priya.new@example.com')))

      expect(contact.reload.email).to eq('priya.new@example.com')
      expect(contact.verified_attributes['email']).to eq('jwt')
    end

    it 'drops claims of the wrong type' do
      identify(identity_token(claims.merge(custom_attributes: 'pro', avatar_url: { url: 'x' }, name: 42)))

      expect(response).to have_http_status(:success)
      expect(contact.reload.identifier).to eq('user-1')
      expect(contact.verified_attributes.keys).to contain_exactly('email', 'phone_number')
    end

    it 'accepts a token that has not expired' do
      identify(identity_token(claims.merge(exp: 5.minutes.from_now.to_i)))

      expect(response).to have_http_status(:success)
    end

    it 'does not store the contact again when the same token is sent again' do
      token = identity_token(claims)
      identify(token)
      allow(Rails.configuration.dispatcher).to receive(:dispatch).and_call_original

      identify(token)

      expect(response).to have_http_status(:success)
      expect(Rails.configuration.dispatcher).not_to have_received(:dispatch).with(Events::Types::CONTACT_UPDATED, any_args)
    end

    it 'keeps the verified values when the session sends other values without a token' do
      identify(identity_token(claims))

      patch '/api/v1/widget/contact',
            params: { website_token: web_widget.website_token, name: 'Someone Else', email: 'someone.else@example.com' },
            headers: { 'X-Auth-Token' => widget_token },
            as: :json

      expect(response).to have_http_status(:success)
      expect(contact.reload).to have_attributes(name: 'Priya', email: 'priya@example.com')
      expect(contact.verified_attributes).to eq('name' => 'jwt', 'email' => 'jwt', 'phone_number' => 'jwt')
    end
  end

  context 'when a visitor without a token reaches the contact' do
    let(:visitor_contact_inbox) { create(:contact_inbox, contact: create(:contact, account: account), inbox: web_widget.inbox) }
    let(:visitor_token) do
      Widget::TokenService.new(payload: { source_id: visitor_contact_inbox.source_id, inbox_id: web_widget.inbox.id }).generate_token
    end

    def visitor_request(path, params)
      patch path, params: { website_token: web_widget.website_token }.merge(params), headers: { 'X-Auth-Token' => visitor_token }, as: :json
    end

    before do
      identify(identity_token(claims))
      visitor_request('/api/v1/widget/contact/set_user', identifier: 'user-1')
    end

    it 'does not let the visitor change the identifier of the contact' do
      visitor_request('/api/v1/widget/contact', identifier: 'someone-else')

      expect(response).to have_http_status(:success)
      expect(contact.reload.identifier).to eq('user-1')
    end

    it 'still finds the contact when its owner sends a token again' do
      visitor_request('/api/v1/widget/contact', identifier: 'someone-else')

      identify(identity_token(claims))

      expect(response.parsed_body['id']).to eq(contact.id)
      expect(contact.reload).to have_attributes(email: 'priya@example.com', phone_number: '+919999888877')
    end

    it 'does not let the visitor merge the contact into another identified contact' do
      other_contact = create(:contact, account: account, identifier: 'user-9')

      visitor_request('/api/v1/widget/contact', identifier: 'user-9')

      expect(contact.reload.identifier).to eq('user-1')
      expect(other_contact.reload.email).to be_nil
    end
  end

  context 'when the session belongs to another identified contact' do
    before { contact.update!(identifier: 'user-0') }

    it 'moves the session to a new contact and returns its session token' do
      identify(identity_token(claims))

      expect(response).to have_http_status(:success)
      body = response.parsed_body
      expect(body['id']).not_to eq(contact.id)
      expect(body['widget_auth_token']).to be_present
      expect(Contact.find(body['id']).identifier).to eq('user-1')
      expect(contact.reload.identifier).to eq('user-0')
    end

    it 'returns to the same contact for each identifier' do
      identify(identity_token(claims))
      first_user = response.parsed_body

      identify(identity_token({ identifier: 'user-2' }), widget_token: first_user['widget_auth_token'])
      second_user = response.parsed_body

      identify(identity_token(claims), widget_token: second_user['widget_auth_token'])

      expect(second_user['id']).not_to eq(first_user['id'])
      expect(response.parsed_body['id']).to eq(first_user['id'])
    end
  end

  context 'when another contact has the signed email' do
    it 'merges with a contact that has no identifier' do
      email_contact = create(:contact, account: account, email: 'priya@example.com')

      identify(identity_token(claims))

      expect(response.parsed_body['id']).to eq(email_contact.id)
      expect(email_contact.reload).to have_attributes(identifier: 'user-1', email: 'priya@example.com')
      expect(email_contact.verified_attributes['email']).to eq('jwt')
    end

    it 'takes the email from an identified contact whose email is not verified' do
      other_contact = create(:contact, account: account, identifier: 'user-9', email: 'priya@example.com')
      allow(Rails.logger).to receive(:info)

      identify(identity_token(claims))

      expect(response).to have_http_status(:success)
      expect(contact.reload.email).to eq('priya@example.com')
      expect(contact.verified_attributes['email']).to eq('jwt')
      expect(other_contact.reload).to have_attributes(identifier: 'user-9', email: nil)
      expect(Rails.logger).to have_received(:info).with(/Moved email from contact #{other_contact.id} to contact #{contact.id}/)
      expect(Rails.logger).not_to have_received(:info).with(/priya@example.com/)
    end

    it 'takes the phone number from an identified contact whose phone number is not verified' do
      other_contact = create(:contact, account: account, identifier: 'user-9', phone_number: '+919999888877')

      identify(identity_token(claims))

      expect(contact.reload.phone_number).to eq('+919999888877')
      expect(contact.verified_attributes['phone_number']).to eq('jwt')
      expect(other_contact.reload.phone_number).to be_nil
    end

    it 'leaves the phone number with a contact that has no identifier and another email' do
      phone_contact = create(:contact, account: account, phone_number: '+919999888877', email: 'someone.else@example.com')
      allow(Rails.logger).to receive(:info)

      identify(identity_token(claims))

      expect(response).to have_http_status(:success)
      expect(contact.reload).to have_attributes(identifier: 'user-1', email: 'priya@example.com', phone_number: nil)
      expect(contact.verified_attributes.keys).to contain_exactly('name', 'email')
      expect(phone_contact.reload).to have_attributes(phone_number: '+919999888877', email: 'someone.else@example.com')
      expect(Rails.logger).to have_received(:info)
        .with(/Skipped verified phone_number of contact #{contact.id}: contact #{phone_contact.id} holds it with another email/)
    end

    it 'leaves the email with an identified contact whose email is verified' do
      other_contact = create(:contact, account: account, identifier: 'user-9')
      other_contact.assign_verified_attributes({ email: 'priya@example.com' }, source: 'jwt')
      other_contact.save!
      allow(Rails.logger).to receive(:info)

      identify(identity_token(claims))

      expect(response).to have_http_status(:success)
      expect(contact.reload).to have_attributes(identifier: 'user-1', name: 'Priya', email: nil)
      expect(contact.verified_attributes.keys).to contain_exactly('name', 'phone_number')
      expect(other_contact.reload.email).to eq('priya@example.com')
      expect(Rails.logger).to have_received(:info).with(/Skipped verified email of contact #{contact.id}.*contact #{other_contact.id}/)
    end
  end

  context 'without a valid token' do
    def expect_unchanged_session
      expect(response).to have_http_status(:unauthorized)
      expect(contact_inbox.reload.hmac_verified).to be(false)
      expect(contact.reload).to have_attributes(identifier: nil, verified_attributes: {})
    end

    it 'rejects a request with no token' do
      identify(nil)

      expect_unchanged_session
    end

    it 'rejects a token signed with another secret' do
      identify(identity_token(claims, secret: 'a' * 64))

      expect_unchanged_session
    end

    it 'rejects an expired token' do
      identify(identity_token(claims.merge(exp: 1.minute.ago.to_i)))

      expect_unchanged_session
    end

    it 'rejects an unsigned token' do
      identify(identity_token(claims, secret: nil, algorithm: 'none'))

      expect_unchanged_session
    end

    it 'does not accept an identifier hash in place of a token' do
      identifier_hash = OpenSSL::HMAC.hexdigest('sha256', web_widget.hmac_token, 'user-1')

      post '/api/v1/widget/contact/identify',
           params: { website_token: web_widget.website_token, identifier: 'user-1', identifier_hash: identifier_hash },
           headers: { 'X-Auth-Token' => widget_token },
           as: :json

      expect_unchanged_session
    end
  end

  context 'when the inbox has no signing key' do
    before { signing_key.destroy! }

    it 'rejects a signed token' do
      identify(identity_token(claims, secret: 'a' * 64))

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects an unsigned token' do
      identify(identity_token(claims, secret: nil, algorithm: 'none'))

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
