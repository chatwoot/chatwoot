require 'rails_helper'

RSpec.describe 'Company contacts API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:company) { create(:company, name: 'Acme', account: account) }

  before { account.enable_features!(:companies) }

  describe 'GET /api/v1/accounts/{account.id}/companies/{company.id}/contacts' do
    it 'returns contacts linked to the company' do
      linked_contact = create(:contact, name: 'Linked Contact', company: company, account: account)
      create(:contact, name: 'Other Contact', account: account)

      get "/api/v1/accounts/#{account.id}/companies/#{company.id}/contacts",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      response_body = response.parsed_body
      expect(response_body['payload'].pluck('id')).to eq([linked_contact.id])
      expect(response_body['payload'].first['company_id']).to eq(company.id)
      expect(response_body['payload'].first['linked_to_current_company']).to be true
      expect(response_body['meta']['total_count']).to eq(1)
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/companies/{company.id}/contacts/search' do
    it 'returns matching contacts that are not already linked to the company' do
      other_company = create(:company, name: 'Other Company', account: account)
      linked_contact = create(:contact, name: 'Jane Current', company: company, account: account)
      available_contact = create(:contact, name: 'Jane Available', account: account)
      assigned_contact = create(:contact, name: 'Jane Assigned', company: other_company, account: account)

      get "/api/v1/accounts/#{account.id}/companies/#{company.id}/contacts/search",
          params: { q: 'Jane' },
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      contact_ids = response.parsed_body['payload'].pluck('id')
      expect(contact_ids).to contain_exactly(available_contact.id, assigned_contact.id)
      expect(contact_ids).not_to include(linked_contact.id)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/companies/{company.id}/contacts' do
    it 'links an existing contact to the company' do
      contact = create(:contact, name: 'Jane Contact', account: account, additional_attributes: { 'city' => 'Berlin' })

      post "/api/v1/accounts/#{account.id}/companies/#{company.id}/contacts",
           params: { contact_id: contact.id },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(contact.reload.company_id).to eq(company.id)
      expect(contact.additional_attributes).to eq('city' => 'Berlin')
      expect(response.parsed_body['payload']['company_id']).to eq(company.id)
      expect(response.parsed_body['payload']['linked_to_current_company']).to be true
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/companies/{company.id}/contacts/{id}' do
    it 'removes a contact from the company' do
      contact = create(:contact, name: 'Jane Contact', company: company, account: account,
                                 additional_attributes: { 'company_name' => 'Acme', 'city' => 'Berlin' })

      delete "/api/v1/accounts/#{account.id}/companies/#{company.id}/contacts/#{contact.id}",
             headers: admin.create_new_auth_token,
             as: :json

      expect(response).to have_http_status(:ok)
      expect(contact.reload.company_id).to be_nil
      expect(contact.additional_attributes).to eq('company_name' => 'Acme', 'city' => 'Berlin')
    end
  end
end
