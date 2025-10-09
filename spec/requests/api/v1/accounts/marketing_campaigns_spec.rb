require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::MarketingCampaigns', type: :request do
  let(:account) { create(:account) }
  let!(:marketing_campaign) { create(:marketing_campaign, account: account) }
  let(:user) { create(:user, account: account, password: 'Test@123456') }
  let(:headers) { user.create_new_auth_token }

  describe 'GET /api/v1/accounts/:account_id/marketing_campaigns' do
    it 'returns all marketing campaigns for the account' do
      get api_v1_account_marketing_campaigns_url(account_id: account.id), headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      body = (response.parsed_body)
      expect(body).to be_an(Array)
      expect(body.first['id']).to eq(marketing_campaign.id)
    end
  end

  describe 'GET /api/v1/accounts/:account_id/marketing_campaigns/:id' do
    it 'returns a single marketing campaign' do
      get api_v1_account_marketing_campaign_url(account_id: account.id, id: marketing_campaign.id), headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      body = (response.parsed_body)
      expect(body['id']).to eq(marketing_campaign.id)
      expect(body['title']).to eq(marketing_campaign.title)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/marketing_campaigns' do
    let(:valid_params) do
      {
        marketing_campaign: {
          title: 'Nueva campaña',
          description: 'Descripción de prueba',
          start_date: Time.zone.today,
          end_date: Time.zone.today + 7.days,
          active: true,
          source_id: 'META-123'
        }
      }
    end

    let(:invalid_params) do
      {
        marketing_campaign: {
          description: 'Sin título'
        }
      }
    end

    it 'creates a marketing campaign with valid params' do
      expect do
        post api_v1_account_marketing_campaigns_url(account_id: account.id),
             params: valid_params,
             headers: headers,
             as: :json
      end.to change(MarketingCampaign, :count).by(1)

      expect(response).to have_http_status(:ok)
      body = (response.parsed_body)
      expect(body['title']).to eq('Nueva campaña')
    end

    it 'returns errors with invalid params' do
      post api_v1_account_marketing_campaigns_url(account_id: account.id),
           params: invalid_params,
           headers: headers,
           as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = (response.parsed_body)
      expect(body['errors']).to include("Title can't be blank")
    end
  end

  describe 'PATCH /api/v1/accounts/:account_id/marketing_campaigns/:id' do
    let(:update_params) do
      {
        marketing_campaign: {
          title: 'Título actualizado'
        }
      }
    end

    it 'updates the campaign' do
      patch api_v1_account_marketing_campaign_url(account_id: account.id, id: marketing_campaign.id),
            params: update_params,
            headers: headers,
            as: :json

      expect(response).to have_http_status(:ok)
      body = (response.parsed_body)
      expect(body['title']).to eq('Título actualizado')
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/marketing_campaigns/:id' do
    it 'deletes the campaign' do
      expect do
        delete api_v1_account_marketing_campaign_url(account_id: account.id, id: marketing_campaign.id),
               headers: headers
      end.to change(MarketingCampaign, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
