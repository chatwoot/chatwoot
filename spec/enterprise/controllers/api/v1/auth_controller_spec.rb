# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Auth', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, email: 'user@example.com') }

  before do
    account.enable_features('saml')
    account.save!
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('FRONTEND_URL', nil).and_return('http://www.example.com')
  end

  describe 'POST /api/v1/auth/saml_login' do
    context 'when email is blank' do
      it 'returns bad request' do
        post '/api/v1/auth/saml_login', params: { email: '' }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when email is nil' do
      it 'returns bad request' do
        post '/api/v1/auth/saml_login', params: {}

        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when user does not exist' do
      it 'redirects to SSO login page with error' do
        post '/api/v1/auth/saml_login', params: { email: 'nonexistent@example.com' }

        expect(response.location).to eq('http://www.example.com/app/login/sso?error=saml-authentication-failed')
      end

      it 'redirects to mobile deep link with error when target is mobile' do
        post '/api/v1/auth/saml_login', params: { email: 'nonexistent@example.com', target: 'mobile' }

        expect(response.location).to eq('chatwootapp://auth/saml?error=saml-authentication-failed')
      end
    end

    context 'when user exists but has no SAML enabled accounts' do
      before do
        create(:account_user, user: user, account: account)
      end

      it 'redirects to SSO login page with error' do
        post '/api/v1/auth/saml_login', params: { email: user.email }

        expect(response.location).to eq('http://www.example.com/app/login/sso?error=saml-authentication-failed')
      end

      it 'redirects to mobile deep link with error when target is mobile' do
        post '/api/v1/auth/saml_login', params: { email: user.email, target: 'mobile' }

        expect(response.location).to eq('chatwootapp://auth/saml?error=saml-authentication-failed')
      end
    end

    context 'when user has account without SAML feature enabled' do
      let(:saml_settings) { create(:account_saml_settings, account: account) }

      before do
        saml_settings
        create(:account_user, user: user, account: account)
        account.disable_features('saml')
        account.save!
      end

      it 'redirects to SSO login page with error' do
        post '/api/v1/auth/saml_login', params: { email: user.email }

        expect(response.location).to eq('http://www.example.com/app/login/sso?error=saml-authentication-failed')
      end

      it 'redirects to mobile deep link with error when target is mobile' do
        post '/api/v1/auth/saml_login', params: { email: user.email, target: 'mobile' }

        expect(response.location).to eq('chatwootapp://auth/saml?error=saml-authentication-failed')
      end
    end

    context 'when user has valid SAML configuration' do
      let(:saml_settings) do
        create(:account_saml_settings, account: account)
      end

      before do
        saml_settings
        create(:account_user, user: user, account: account)
      end

      it 'redirects to SAML initiation URL' do
        post '/api/v1/auth/saml_login', params: { email: user.email }

        expect(response.location).to include("/auth/saml?account_id=#{account.id}")
      end

      it 'redirects to SAML initiation URL with mobile relay state' do
        post '/api/v1/auth/saml_login', params: { email: user.email, target: 'mobile' }

        expect(response.location).to include("/auth/saml?account_id=#{account.id}&RelayState=mobile")
      end
    end

    context 'when user has multiple accounts with SAML' do
      let(:account2) { create(:account) }
      let(:saml_settings1) do
        create(:account_saml_settings, account: account)
      end
      let(:saml_settings2) do
        create(:account_saml_settings, account: account2)
      end

      before do
        account2.enable_features('saml')
        account2.save!
        saml_settings1
        saml_settings2
        create(:account_user, user: user, account: account)
        create(:account_user, user: user, account: account2)
      end

      it 'redirects to the first SAML enabled account' do
        post '/api/v1/auth/saml_login', params: { email: user.email }

        returned_account_id = response.location.match(/account_id=(\d+)/)[1].to_i
        expect([account.id, account2.id]).to include(returned_account_id)
      end
    end
  end
end
