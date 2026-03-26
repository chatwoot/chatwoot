require 'rails_helper'

RSpec.describe 'Company contacts API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:company) { create(:company, account: account, twenty_id: 'company-123') }

  describe 'GET /api/v1/accounts/{account.id}/companies/{id}/contacts' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/companies/#{company.id}/contacts"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let!(:matching_contact) { create(:contact, :with_email, account: account, company: company, twenty_id: 'person-123') }
      let!(:other_company_contact) { create(:contact, :with_email, account: account, company: create(:company, account: account)) }

      it 'returns the normal contacts envelope for the company scoped contacts list' do
        get "/api/v1/accounts/#{account.id}/companies/#{company.id}/contacts",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['meta']).to include('count' => 1, 'current_page' => 1)
        expect(response.parsed_body['payload'].pluck('id')).to contain_exactly(matching_contact.id)
      end

      it 'stays account scoped' do
        other_account = create(:account)
        other_company = create(:company, account: other_account)
        create(:contact, :with_email, account: other_account, company: other_company)

        get "/api/v1/accounts/#{account.id}/companies/#{other_company.id}/contacts",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'is policy checked like the rest of the company surface' do
        allow_any_instance_of(CompanyPolicy).to receive(:show?).and_return(false)

        get "/api/v1/accounts/#{account.id}/companies/#{company.id}/contacts",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['error']).to eq('You are not authorized to do this action')
      end
    end
  end
end
