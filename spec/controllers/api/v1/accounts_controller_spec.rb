require 'rails_helper'

RSpec.describe 'Accounts API', type: :request do
  describe 'POST /api/v1/accounts' do
    context 'when posting to accounts with correct parameters' do
      let(:account_builder) { double }
      let(:email) { Faker::Internet.email }
      let(:user) { create(:user, email: email) }

      before do
        allow(AccountBuilder).to receive(:new).and_return(account_builder)
        allow(account_builder).to receive(:perform).and_return(user)
      end

      it 'calls account builder' do
        params = { account_name: 'test', email: email }

        post api_v1_accounts_url,
             params: params,
             as: :json

        expect(AccountBuilder).to have_received(:new).with(params)
        expect(account_builder).to have_received(:perform)
        expect(response.headers.keys).to include('access-token', 'token-type', 'client', 'expiry', 'uid')
      end
    end
  end
end
