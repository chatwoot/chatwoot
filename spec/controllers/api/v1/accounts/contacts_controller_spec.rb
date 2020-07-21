require 'rails_helper'

RSpec.describe 'Contacts API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/accounts/{account.id}/contacts' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let!(:contact) { create(:contact, account: account) }

      it 'returns all contacts' do
        get "/api/v1/accounts/#{account.id}/contacts",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(contact.email)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/contacts/:id' do
    let!(:contact) { create(:contact, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'shows the contact' do
        get "/api/v1/accounts/#{account.id}/contacts/#{contact.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(contact.email)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/contacts' do
    let(:valid_params) { { contact: { name: 'test' } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/contacts", params: valid_params }.to change(Contact, :count).by(0)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:inbox) { create(:inbox, account: account) }

      it 'creates the contact' do
        expect do
          post "/api/v1/accounts/#{account.id}/contacts", headers: admin.create_new_auth_token,
                                                          params: valid_params
        end.to change(Contact, :count).by(1)

        expect(response).to have_http_status(:success)
      end

      it 'creates the contact identifier when inbox id is passed' do
        expect do
          post "/api/v1/accounts/#{account.id}/contacts", headers: admin.create_new_auth_token,
                                                          params: valid_params.merge({ inbox_id: inbox.id })
        end.to change(ContactInbox, :count).by(1)

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/contacts/:id' do
    let!(:contact) { create(:contact, account: account) }
    let(:valid_params) { { contact: { name: 'Test Blub' } } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/contacts/#{contact.id}",
            params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'updates the contact' do
        patch "/api/v1/accounts/#{account.id}/contacts/#{contact.id}",
              headers: admin.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:success)
        expect(Contact.last.name).to eq('Test Blub')
      end

      it 'prevents the update of contact of another account' do
        other_account = create(:account)
        other_contact = create(:contact, account: other_account)

        patch "/api/v1/accounts/#{account.id}/contacts/#{other_contact.id}",
              headers: admin.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
