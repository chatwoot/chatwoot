require 'rails_helper'

RSpec.describe Enterprise::Api::V2::AccountsController, type: :request do
  let(:email) { Faker::Internet.email }
  let(:user) { create(:user) }
  let(:account) { create(:account) }
  let(:clearbit_data) do
    {
      name: 'John Doe',
      company_name: 'Acme Inc',
      industry: 'Software',
      company_size: '51-200',
      timezone: 'America/Los_Angeles',
      logo: 'https://logo.clearbit.com/acme.com'
    }
  end

  before do
    allow(Enterprise::ClearbitLookupService).to receive(:lookup).and_return(clearbit_data)
  end

  describe 'POST /api/v1/accounts' do
    let(:account_builder) { double }
    let(:account) { create(:account) }
    let(:user) { create(:user, email: email, account: account) }

    before do
      allow(AccountBuilder).to receive(:new).and_return(account_builder)
    end

    it 'fetches data from clearbit and updates user and account info' do
      with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true' do
        allow(account_builder).to receive(:perform).and_return([user, account])

        params = { email: email, user: nil, locale: nil, password: 'Password1!' }

        post api_v2_accounts_url,
             params: params,
             as: :json

        expect(AccountBuilder).to have_received(:new).with(params.except(:password).merge(user_password: params[:password]))
        expect(account_builder).to have_received(:perform)
        expect(Enterprise::ClearbitLookupService).to have_received(:lookup).with(email)

        custom_attributes = account.custom_attributes

        expect(account.name).to eq('Acme Inc')
        expect(custom_attributes['industry']).to eq('Software')
        expect(custom_attributes['company_size']).to eq('51-200')
        expect(custom_attributes['timezone']).to eq('America/Los_Angeles')
      end
    end

    it 'updates the onboarding step in custom attributes' do
      with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true' do
        allow(account_builder).to receive(:perform).and_return([user, account])

        params = { email: email, user: nil, locale: nil, password: 'Password1!' }

        post api_v2_accounts_url,
             params: params,
             as: :json

        custom_attributes = account.custom_attributes

        expect(custom_attributes['onboarding_step']).to eq('profile_update')
      end
    end

    it 'handles errors when fetching data from clearbit' do
      with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true' do
        allow(account_builder).to receive(:perform).and_return([user, account])
        allow(Enterprise::ClearbitLookupService).to receive(:lookup).and_raise(StandardError)
        params = { email: email, user: nil, locale: nil, password: 'Password1!' }

        post api_v2_accounts_url,
             params: params,
             as: :json

        expect(AccountBuilder).to have_received(:new).with(params.except(:password).merge(user_password: params[:password]))
        expect(account_builder).to have_received(:perform)
        expect(Enterprise::ClearbitLookupService).to have_received(:lookup).with(email)

        expect(response).to have_http_status(:success)
      end
    end
  end
end
