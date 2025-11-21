require 'rails_helper'

RSpec.describe 'Accounts API Repro', type: :request do
  describe 'POST /api/v1/accounts' do
    let(:email) { Faker::Internet.email }
    let(:user_full_name) { Faker::Name.name_with_middle }

    context 'when AccountBuilder raises ActiveRecord::RecordInvalid' do
      let(:account_builder) { double }

      before do
        allow(AccountBuilder).to receive(:new).and_return(account_builder)
        # Simulate a validation error that raises RecordInvalid
        allow(account_builder).to receive(:perform).and_raise(StandardError.new("Something went wrong"))
      end

      it 'returns 422 Unprocessable Entity instead of 500' do
        with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true' do
          params = { account_name: 'test', email: email, user: nil, locale: nil, user_full_name: user_full_name, password: 'Password1!' }

          post api_v1_accounts_url,
               params: params,
               as: :json

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end
end
