require 'rails_helper'

RSpec.describe '/api/v1/accounts/{account.id}/contacts/:id/contact_inboxes', type: :request do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, email: 'f.o.o.b.a.r@gmail.com') }
  let(:channel_twilio_sms) { create(:channel_twilio_sms, account: account) }
  let(:channel_email) { create(:channel_email, account: account) }
  let(:channel_api) { create(:channel_api, account: account) }
  let(:agent) { create(:user, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/contacts/:id/contact_inboxes' do
    context 'when unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/contact_inboxes"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated user with access to inbox' do
      it 'creates a contact inbox' do
        create(:inbox_member, inbox: channel_api.inbox, user: agent)
        expect do
          post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/contact_inboxes",
               params: { inbox_id: channel_api.inbox.id },
               headers: agent.create_new_auth_token,
               as: :json
        end.to change(ContactInbox, :count).by(1)

        expect(response).to have_http_status(:success)
        contact_inbox = contact.reload.contact_inboxes.find_by(inbox_id: channel_api.inbox.id)
        expect(contact_inbox).to be_present
        expect(contact_inbox.hmac_verified).to be(false)
      end

      it 'creates a valid email contact inbox' do
        create(:inbox_member, inbox: channel_email.inbox, user: agent)
        expect do
          post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/contact_inboxes",
               params: { inbox_id: channel_email.inbox.id },
               headers: agent.create_new_auth_token,
               as: :json
        end.to change(ContactInbox, :count).by(1)

        expect(response).to have_http_status(:success)
        expect(contact.reload.contact_inboxes.map(&:inbox_id)).to include(channel_email.inbox.id)
      end

      it 'creates an hmac verified contact inbox' do
        create(:inbox_member, inbox: channel_api.inbox, user: agent)
        expect do
          post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/contact_inboxes",
               params: { inbox_id: channel_api.inbox.id, hmac_verified: true },
               headers: agent.create_new_auth_token,
               as: :json
        end.to change(ContactInbox, :count).by(1)

        expect(response).to have_http_status(:success)
        contact_inbox = contact.reload.contact_inboxes.find_by(inbox_id: channel_api.inbox.id)
        expect(contact_inbox).to be_present
        expect(contact_inbox.hmac_verified).to be(true)
      end

      it 'throws error for invalid source id' do
        create(:inbox_member, inbox: channel_twilio_sms.inbox, user: agent)
        expect do
          post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/contact_inboxes",
               params: { inbox_id: channel_twilio_sms.inbox.id },
               headers: agent.create_new_auth_token,
               as: :json
        end.not_to change(ContactInbox, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
