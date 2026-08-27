require 'rails_helper'

RSpec.describe 'Enterprise Contacts API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  before { account.enable_features!(:companies) }

  describe 'PATCH /api/v1/accounts/{account.id}/contacts/:id' do
    it 'updates company association' do
      company = create(:company, account: account, name: 'Acme')
      contact = create(:contact, account: account)

      patch "/api/v1/accounts/#{account.id}/contacts/#{contact.id}",
            headers: admin.create_new_auth_token,
            params: { company_id: company.id },
            as: :json

      expect(response).to have_http_status(:success)
      expect(contact.reload.company).to eq(company)
      expect(contact.additional_attributes['company_name']).to eq('Acme')
    end
  end
end
