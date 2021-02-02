require 'rails_helper'

RSpec.describe '/api/v1/accounts/{account.id}/contacts/:id/contact_inboxes', type: :request do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }
  let(:channel_twilio_sms) { create(:channel_twilio_sms, account: account) }
  let(:channel_api) { create(:channel_api, account: account) }
  let(:user) { create(:user, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/contacts/:id/contact_inboxes' do
    context 'when unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/contact_inboxes"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is logged in' do
      it 'creates a contact inbox' do
        expect do
          post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/contact_inboxes",
               params: { inbox_id: channel_api.inbox.id },
               headers: user.create_new_auth_token,
               as: :json
        end.to change(ContactInbox, :count).by(1)

        expect(response).to have_http_status(:success)
        expect(contact.reload.contact_inboxes.map(&:inbox_id)).to include(channel_api.inbox.id)
      end

      it 'throws error for invalid source id' do
        expect do
          post "/api/v1/accounts/#{account.id}/contacts/#{contact.id}/contact_inboxes",
               params: { inbox_id: channel_twilio_sms.inbox.id },
               headers: user.create_new_auth_token,
               as: :json
        end.to change(ContactInbox, :count).by(0)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
