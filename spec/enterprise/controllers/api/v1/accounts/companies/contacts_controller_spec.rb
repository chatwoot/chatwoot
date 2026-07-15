require 'rails_helper'

RSpec.describe 'Company contacts API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:company) do
    create(:company, name: 'Acme', domain: 'acme.com', description: 'Primary account', account: account,
                     custom_attributes: { 'industry' => 'Manufacturing' })
  end

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
      contact_payload = response_body['payload'].first
      expect(contact_payload['company_id']).to eq(company.id)
      expect(contact_payload['linked_to_current_company']).to be true
      expect(contact_payload['company']).to include(
        'id' => company.id,
        'name' => 'Acme',
        'domain' => 'acme.com',
        'description' => 'Primary account',
        'custom_attributes' => { 'industry' => 'Manufacturing' }
      )
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
      response_payload = response.parsed_body['payload']
      contact_ids = response_payload.pluck('id')
      expect(contact_ids).to contain_exactly(available_contact.id, assigned_contact.id)
      expect(contact_ids).not_to include(linked_contact.id)
      expect(response_payload.find { |contact| contact['id'] == assigned_contact.id }['company']).to include(
        'id' => other_company.id,
        'name' => 'Other Company'
      )
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/companies/{company.id}/contacts' do
    it 'links an existing contact to the company' do
      contact = create(:contact, name: 'Jane Contact', account: account, last_activity_at: 1.hour.ago,
                                 additional_attributes: { 'city' => 'Berlin' })

      post "/api/v1/accounts/#{account.id}/companies/#{company.id}/contacts",
           params: { contact_id: contact.id },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(contact.reload.company_id).to eq(company.id)
      expect(contact.additional_attributes).to eq('city' => 'Berlin', 'company_name' => 'Acme')
      expect(response.parsed_body['payload']['company_id']).to eq(company.id)
      expect(response.parsed_body['payload']['linked_to_current_company']).to be true
      expect(company.reload.last_activity_at).to be_within(1.second).of(contact.last_activity_at)
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
      expect(contact.additional_attributes).to eq('city' => 'Berlin')
    end
  end
end
