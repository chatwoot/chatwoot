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
      let!(:contact_inbox) { create(:contact_inbox, contact: contact) }

      it 'returns all contacts with contact inboxes' do
        get "/api/v1/accounts/#{account.id}/contacts",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(contact.email)
        expect(response.body).to include(contact_inbox.source_id)
        expect(response.body).to include(contact_inbox.inbox.name)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/contacts/active' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts/active"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let!(:contact) { create(:contact, account: account) }

      it 'returns no contacts if no are online' do
        get "/api/v1/accounts/#{account.id}/contacts/active",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include(contact.email)
      end

      it 'returns all contacts who are online' do
        allow(::OnlineStatusTracker).to receive(:get_available_contact_ids).and_return([contact.id])

        get "/api/v1/accounts/#{account.id}/contacts/active",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(contact.email)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/contacts/search' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/contacts/search"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let!(:contact1) { create(:contact, account: account) }
      let!(:contact2) { create(:contact, account: account, email: 'test@test.com') }

      it 'returns all contacts with contact inboxes' do
        get "/api/v1/accounts/#{account.id}/contacts/search",
            params: { q: contact2.email },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(contact2.email)
        expect(response.body).not_to include(contact1.email)
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
    let(:custom_attributes) { { test: 'test', test1: 'test1' } }
    let(:valid_params) { { contact: { name: 'test', custom_attributes: custom_attributes } } }

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

        # custom attributes are updated
        json_response = JSON.parse(response.body)
        expect(json_response['payload']['contact']['custom_attributes']).to eq({ 'test' => 'test', 'test1' => 'test1' })
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
    let(:custom_attributes) { { test: 'test', test1: 'test1' } }
    let!(:contact) { create(:contact, account: account, custom_attributes: custom_attributes) }
    let(:valid_params) { { contact: { name: 'Test Blub', custom_attributes: { test: 'new test', test2: 'test2' } } } }

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
        expect(contact.reload.name).to eq('Test Blub')
        # custom attributes are merged properly without overwritting existing ones
        expect(contact.custom_attributes).to eq({ 'test' => 'new test', 'test1' => 'test1', 'test2' => 'test2' })
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

      it 'prevents updating with an existing email' do
        other_contact = create(:contact, account: account, email: 'test1@example.com')

        patch "/api/v1/accounts/#{account.id}/contacts/#{contact.id}",
              headers: admin.create_new_auth_token,
              params: valid_params[:contact].merge({ email: other_contact.email }),
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['contact']['id']).to eq(other_contact.id)
      end
    end
  end
end
