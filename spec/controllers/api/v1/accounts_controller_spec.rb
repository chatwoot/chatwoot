require 'rails_helper'

RSpec.describe 'Accounts API', type: :request do
  describe 'POST /api/v1/accounts' do
    context 'when posting to accounts with correct parameters' do
      let(:account_builder) { double }
      let(:email) { Faker::Internet.email }
      let(:user) { create(:user, email: email) }

      before do
        allow(AccountBuilder).to receive(:new).and_return(account_builder)
        ENV['ENABLE_ACCOUNT_SIGNUP'] = nil
      end

      it 'calls account builder' do
        allow(account_builder).to receive(:perform).and_return(user)

        params = { account_name: 'test', email: email }

        post api_v1_accounts_url,
             params: params,
             as: :json

        expect(AccountBuilder).to have_received(:new).with(params)
        expect(account_builder).to have_received(:perform)
        expect(response.headers.keys).to include('access-token', 'token-type', 'client', 'expiry', 'uid')
      end

      it 'renders error response on invalid params' do
        allow(account_builder).to receive(:perform).and_return(nil)

        params = { account_name: nil, email: nil }

        post api_v1_accounts_url,
             params: params,
             as: :json

        expect(AccountBuilder).to have_received(:new).with(params)
        expect(account_builder).to have_received(:perform)
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq({ message: I18n.t('errors.signup.failed') }.to_json)
      end
    end

    context 'when ENABLE_ACCOUNT_SIGNUP env variable is set to false' do
      let(:email) { Faker::Internet.email }

      it 'responds 404 on requests' do
        params = { account_name: 'test', email: email }
        ENV['ENABLE_ACCOUNT_SIGNUP'] = 'false'

        post api_v1_accounts_url,
             params: params,
             as: :json

        expect(response).to have_http_status(:not_found)
        ENV['ENABLE_ACCOUNT_SIGNUP'] = nil
      end
    end

    context 'when ENABLE_ACCOUNT_SIGNUP env variable is set to api_only' do
      let(:email) { Faker::Internet.email }

      it 'does not respond 404 on requests' do
        params = { account_name: 'test', email: email }
        ENV['ENABLE_ACCOUNT_SIGNUP'] = 'api_only'

        post api_v1_accounts_url,
             params: params,
             as: :json

        expect(response).not_to have_http_status(:not_found)
        ENV['ENABLE_ACCOUNT_SIGNUP'] = nil
      end
    end
  end
end
