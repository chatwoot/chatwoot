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
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/companies/{id}' do
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
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/companies/{id}' do
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
