require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Crm::Leads', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:pipeline) { create(:crm_pipeline, account: account) }
  let(:stage) { create(:crm_stage, crm_pipeline: pipeline) }
  let(:contact) { create(:contact, account: account) }
  let!(:lead) { create(:crm_lead, account: account, crm_stage: stage, contact: contact) }

  describe 'GET /api/v1/accounts/{account.id}/crm/leads' do
    context 'when it is an authenticated user' do
      it 'returns all leads' do
        get "/api/v1/accounts/#{account.id}/crm/leads",
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body).size).to eq(1)
        expect(JSON.parse(response.body).first['id']).to eq(lead.id)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/crm/leads' do
    context 'when it is an authenticated user' do
      it 'creates a lead' do
        post "/api/v1/accounts/#{account.id}/crm/leads",
             params: { crm_lead: { title: 'New Lead', crm_stage_id: stage.id, contact_id: contact.id } },
             headers: user.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['title']).to eq('New Lead')
      end
    end
  end
end
