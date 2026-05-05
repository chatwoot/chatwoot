require 'rails_helper'

RSpec.describe 'Companies API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/accounts/{account.id}/companies' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/companies"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let!(:company1) { create(:company, name: 'Company 1', account: account) }
      let!(:company2) { create(:company, account: account) }

      it 'returns all companies' do
        get "/api/v1/accounts/#{account.id}/companies",
            headers: admin.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        expect(response_body['payload'].size).to eq(2)
        expect(response_body['payload'].map { |c| c['name'] }).to contain_exactly(company1.name, company2.name)
      end

      it 'returns companies with pagination' do
        create_list(:company, 30, account: account)

        get "/api/v1/accounts/#{account.id}/companies",
            params: { page: 1 },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        expect(response_body['payload'].size).to eq(25)
        expect(response_body['meta']['total_count']).to eq(32)
        expect(response_body['meta']['page']).to eq(1)
      end

      it 'returns second page of companies' do
        create_list(:company, 30, account: account)
        get "/api/v1/accounts/#{account.id}/companies",
            params: { page: 2 },
            headers: admin.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        expect(response_body['payload'].size).to eq(7)
        expect(response_body['meta']['total_count']).to eq(32)
        expect(response_body['meta']['page']).to eq(2)
      end

      it 'returns companies with contacts_count' do
        company_with_contacts = create(:company, name: 'Company With Contacts', account: account)
        create_list(:contact, 5, company: company_with_contacts, account: account)

        get "/api/v1/accounts/#{account.id}/companies",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        company_data = response_body['payload'].find { |c| c['id'] == company_with_contacts.id }
        expect(company_data['contacts_count']).to eq(5)
      end

      it 'returns account owner details for owned and unowned companies' do
        owner = create(:user, account: account)
        company1.update!(account_owner: owner)

        get "/api/v1/accounts/#{account.id}/companies",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        owned_company_payload = response_body['payload'].find { |c| c['id'] == company1.id }
        unowned_company_payload = response_body['payload'].find { |c| c['id'] == company2.id }

        expect(owned_company_payload['account_owner_id']).to eq(owner.id)
        expect(owned_company_payload['account_owner']['id']).to eq(owner.id)
        expect(unowned_company_payload['account_owner_id']).to be_nil
        expect(unowned_company_payload['account_owner']).to be_nil
      end

      it 'does not return companies from other accounts' do
        other_account = create(:account)
        create(:company, name: 'Other Account Company', account: other_account)
        create(:company, name: 'My Company', account: account)
        get "/api/v1/accounts/#{account.id}/companies",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        expect(response_body['payload'].size).to eq(3)
        expect(response_body['payload'].map { |c| c['name'] }).not_to include('Other Account Company')
      end

      it 'sorts companies by contacts_count in ascending order' do
        company_with_5 = create(:company, name: 'Company with 5', account: account)
        company_with_2 = create(:company, name: 'Company with 2', account: account)
        company_with_10 = create(:company, name: 'Company with 10', account: account)
        create_list(:contact, 5, company: company_with_5, account: account)
        create_list(:contact, 2, company: company_with_2, account: account)
        create_list(:contact, 10, company: company_with_10, account: account)

        get "/api/v1/accounts/#{account.id}/companies",
            params: { sort: 'contacts_count' },
            headers: admin.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        company_ids = response_body['payload'].map { |c| c['id'] }

        expect(company_ids.index(company_with_2.id)).to be < company_ids.index(company_with_5.id)
        expect(company_ids.index(company_with_5.id)).to be < company_ids.index(company_with_10.id)
      end

      it 'sorts companies by contacts_count in descending order' do
        company_with_5 = create(:company, name: 'Company with 5', account: account)
        company_with_2 = create(:company, name: 'Company with 2', account: account)
        company_with_10 = create(:company, name: 'Company with 10', account: account)
        create_list(:contact, 5, company: company_with_5, account: account)
        create_list(:contact, 2, company: company_with_2, account: account)
        create_list(:contact, 10, company: company_with_10, account: account)

        get "/api/v1/accounts/#{account.id}/companies",
            params: { sort: '-contacts_count' },
            headers: admin.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        company_ids = response_body['payload'].map { |c| c['id'] }

        expect(company_ids.index(company_with_10.id)).to be < company_ids.index(company_with_5.id)
        expect(company_ids.index(company_with_5.id)).to be < company_ids.index(company_with_2.id)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/companies/search' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/companies/search"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'returns error when q parameter is missing' do
        get "/api/v1/accounts/#{account.id}/companies/search",
            headers: admin.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Specify search string with parameter q')
      end

      it 'searches companies by name' do
        create(:company, name: 'Acme Corp', domain: 'acme.com', account: account)
        create(:company, name: 'Tech Solutions', domain: 'tech.com', account: account)
        create(:company, name: 'Global Inc', domain: 'global.com', account: account)

        get "/api/v1/accounts/#{account.id}/companies/search",
            params: { q: 'tech' },
            headers: admin.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        expect(response_body['payload'].size).to eq(1)
        expect(response_body['payload'].first['name']).to eq('Tech Solutions')
      end

      it 'searches companies by domain' do
        create(:company, name: 'Acme Corp', domain: 'acme.com', account: account)
        create(:company, name: 'Tech Solutions', domain: 'tech.com', account: account)
        create(:company, name: 'Global Inc', domain: 'global.com', account: account)

        get "/api/v1/accounts/#{account.id}/companies/search",
            params: { q: 'acme.com' },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        expect(response_body['payload'].size).to eq(1)
        expect(response_body['payload'].first['domain']).to eq('acme.com')
      end

      it 'search is case insensitive' do
        create(:company, name: 'Acme Corp', domain: 'acme.com', account: account)
        get "/api/v1/accounts/#{account.id}/companies/search",
            params: { q: 'ACME' },
            headers: admin.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:success)
        response_body = response.parsed_body

        expect(response_body['payload'].size).to eq(1)
      end

      it 'returns empty array when no companies match search' do
        create(:company, name: 'Acme Corp', domain: 'acme.com', account: account)
        get "/api/v1/accounts/#{account.id}/companies/search",
            params: { q: 'nonexistent' },
            headers: admin.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        expect(response_body['payload'].size).to eq(0)
        expect(response_body['meta']['total_count']).to eq(0)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/companies/{id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        company = create(:company, account: account)
        get "/api/v1/accounts/#{account.id}/companies/#{company.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:company) { create(:company, account: account) }

      it 'returns the company' do
        get "/api/v1/accounts/#{account.id}/companies/#{company.id}",
            headers: admin.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        expect(response_body['payload']['name']).to eq(company.name)
        expect(response_body['payload']['id']).to eq(company.id)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/companies' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/companies"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:valid_params) do
        {
          company: {
            name: 'New Company',
            domain: 'newcompany.com',
            description: 'A new company'
          }
        }
      end

      it 'creates a new company' do
        expect do
          post "/api/v1/accounts/#{account.id}/companies",
               params: valid_params,
               headers: admin.create_new_auth_token,
               as: :json
        end.to change(Company, :count).by(1)

        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        expect(response_body['payload']['name']).to eq('New Company')
        expect(response_body['payload']['domain']).to eq('newcompany.com')
      end

      it 'creates a new company with an account owner' do
        owner = create(:user, account: account)

        expect do
          post "/api/v1/accounts/#{account.id}/companies",
               params: {
                 company: {
                   name: 'New Company',
                   domain: 'newcompany.com',
                   description: 'A new company',
                   account_owner_id: owner.id
                 }
               },
               headers: admin.create_new_auth_token,
               as: :json
        end.to change(Company, :count).by(1)

        expect(response).to have_http_status(:success)

        company = Company.last
        expect(company.account_owner).to eq(owner)

        response_body = response.parsed_body
        expect(response_body['payload']['account_owner_id']).to eq(owner.id)
        expect(response_body['payload']['account_owner']['id']).to eq(owner.id)
      end

      it 'rejects an account owner from another account' do
        other_owner = create(:user, account: create(:account))

        expect do
          post "/api/v1/accounts/#{account.id}/companies",
               params: {
                 company: {
                   name: 'New Company',
                   domain: 'newcompany.com',
                   description: 'A new company',
                   account_owner_id: other_owner.id
                 }
               },
               headers: admin.create_new_auth_token,
               as: :json
        end.not_to change(Company, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['message']).to include(
          'Account owner must belong to the same account as the company'
        )
      end

      it 'returns error for invalid params' do
        invalid_params = { company: { name: '' } }

        post "/api/v1/accounts/#{account.id}/companies",
             params: invalid_params,
             headers: admin.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/companies/{id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        company = create(:company, account: account)
        patch "/api/v1/accounts/#{account.id}/companies/#{company.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:company) { create(:company, account: account) }
      let(:update_params) do
        {
          company: {
            name: 'Updated Company Name',
            domain: 'updated.com'
          }
        }
      end

      it 'updates the company' do
        patch "/api/v1/accounts/#{account.id}/companies/#{company.id}",
              params: update_params,
              headers: admin.create_new_auth_token,
              as: :json
        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        expect(response_body['payload']['name']).to eq('Updated Company Name')
        expect(response_body['payload']['domain']).to eq('updated.com')
      end

      it 'updates the account owner' do
        owner = create(:user, account: account)

        patch "/api/v1/accounts/#{account.id}/companies/#{company.id}",
              params: { company: { account_owner_id: owner.id } },
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(company.reload.account_owner).to eq(owner)

        response_body = response.parsed_body
        expect(response_body['payload']['account_owner_id']).to eq(owner.id)
        expect(response_body['payload']['account_owner']['email']).to eq(owner.email)
      end

      it 'rejects an account owner from another account' do
        other_owner = create(:user, account: create(:account))

        patch "/api/v1/accounts/#{account.id}/companies/#{company.id}",
              params: { company: { account_owner_id: other_owner.id } },
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(company.reload.account_owner_id).to be_nil
        expect(response.parsed_body['message']).to include(
          'Account owner must belong to the same account as the company'
        )
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/companies/{id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        company = create(:company, account: account)
        delete "/api/v1/accounts/#{account.id}/companies/#{company.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let(:admin) { create(:user, account: account, role: :administrator) }
      let(:company) { create(:company, account: account) }

      it 'deletes the company' do
        company
        expect do
          delete "/api/v1/accounts/#{account.id}/companies/#{company.id}",
                 headers: admin.create_new_auth_token,
                 as: :json
        end.to change(Company, :count).by(-1)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when it is a regular agent' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:company) { create(:company, account: account) }

      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/companies/#{company.id}",
               headers: agent.create_new_auth_token,
               as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
