require 'rails_helper'

RSpec.describe 'Contact Inboxes API', type: :request do
  let(:account) { create(:account) }

  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }

  describe 'POST /api/v1/accounts/{account.id}/contact_inboxes/filter' do
    let(:admin) { create(:user, account: account, role: :administrator) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/contact_inboxes/filter"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin user' do
      it 'returns not found if the params are invalid' do
        post "/api/v1/accounts/#{account.id}/contact_inboxes/filter",
             headers: admin.create_new_auth_token,
             params: { inbox_id: inbox.id, source_id: 'random_source_id' },
             as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns the contact if the params are valid' do
        post "/api/v1/accounts/#{account.id}/contact_inboxes/filter",
             headers: admin.create_new_auth_token,
             params: { inbox_id: inbox.id, source_id: contact_inbox.source_id },
             as: :json

        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        expect(response_body['id']).to eq(contact.id)
        expect(response_body['contact_inboxes'].first['source_id']).to eq(contact_inbox.source_id)
      end
    end

    context 'when it is an authenticated agent user' do
      let(:agent_with_inbox_access) { create(:user, account: account, role: :agent) }
      let(:agent_without_inbox_access) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, user: agent_with_inbox_access, inbox: inbox)
      end

      it 'returns unauthorized if agent does not have inbox access' do
        post "/api/v1/accounts/#{account.id}/contact_inboxes/filter",
             headers: agent_without_inbox_access.create_new_auth_token,
             params: { inbox_id: inbox.id, source_id: contact_inbox.source_id },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns success if agent have inbox access' do
        post "/api/v1/accounts/#{account.id}/contact_inboxes/filter",
             headers: agent_with_inbox_access.create_new_auth_token,
             params: { inbox_id: inbox.id, source_id: contact_inbox.source_id },
             as: :json

        expect(response).to have_http_status(:success)
      end
    end

    context 'when authenticated via a read-only api_access_token' do
      it 'returns the contact since the filter lookup is read-only' do
        post "/api/v1/accounts/#{account.id}/contact_inboxes/filter",
             headers: { api_access_token: admin.read_only_access_token.token },
             params: { inbox_id: inbox.id, source_id: contact_inbox.source_id },
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['id']).to eq(contact.id)
      end
    end
  end
end
