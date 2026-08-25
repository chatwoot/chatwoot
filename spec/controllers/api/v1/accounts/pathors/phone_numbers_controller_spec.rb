require 'rails_helper'

RSpec.describe 'Pathors Phone Numbers API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:numbers_url) { 'https://api.pathors.com/project/proj_123/integration/chatwoot/phone_numbers' }
  let(:number_payload) do
    { id: 'pn_x9k2', phone_number: '+886277001234', extension: nil, label: '台北客服代表號', status: 'active', binding: nil }
  end

  describe 'GET /api/v1/accounts/{account.id}/pathors/phone_numbers' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/pathors/phone_numbers"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an administrator' do
      before { create(:integrations_hook, :pathors, account: account, access_token: 'pathors_access_token') }

      it 'passes the registry payload through' do
        stub_request(:get, numbers_url)
          .to_return(status: 200, body: { payload: [number_payload] }.to_json, headers: { 'Content-Type' => 'application/json' })

        get "/api/v1/accounts/#{account.id}/pathors/phone_numbers", headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].pluck('id')).to eq(['pn_x9k2'])
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized' do
        create(:integrations_hook, :pathors, account: account)

        get "/api/v1/accounts/#{account.id}/pathors/phone_numbers", headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent bot' do
      it 'returns unauthorized' do
        create(:integrations_hook, :pathors, account: account)

        get "/api/v1/accounts/#{account.id}/pathors/phone_numbers",
            headers: { api_access_token: create(:agent_bot, account: account).access_token.token }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the integration is not connected' do
      it 'returns not found' do
        get "/api/v1/accounts/#{account.id}/pathors/phone_numbers", headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body['error']).to eq('integration_not_connected')
      end
    end
  end
end
