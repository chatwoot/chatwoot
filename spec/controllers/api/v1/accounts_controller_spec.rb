require 'rails_helper'

RSpec.describe 'Accounts API', type: :request do
  describe 'POST /api/v1/accounts' do
    context 'when posting to accounts with correct parameters' do
      let(:email) { Faker::Internet.email }

      it 'calls account builder' do
        params = { account_name: 'test', email: email }

        post api_v1_accounts_url,
             params: params,
             as: :json

        json_response = JSON.parse(response.body)

        expect(response.headers.keys).to include('access-token', 'token-type', 'client', 'expiry', 'uid')
        expect(response.status).to eq 200
        expect(json_response['data']['email']).to eq email
        expect(json_response['data']['role']).to eq 'administrator'
      end
    end
  end
end
