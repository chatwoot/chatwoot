# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Auth', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, email: 'user@example.com') }

  before do
    account.enable_features('saml')
    account.save!
  end

  def json_response
    JSON.parse(response.body, symbolize_names: true)
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
      it 'returns unauthorized with generic message' do
        post '/api/v1/auth/saml_login', params: { email: 'nonexistent@example.com' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user exists but has no SAML enabled accounts' do
      before do
        create(:account_user, user: user, account: account)
      end

      it 'returns unauthorized' do
        post '/api/v1/auth/saml_login', params: { email: user.email }

        expect(response).to have_http_status(:unauthorized)
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

      it 'returns unauthorized' do
        post '/api/v1/auth/saml_login', params: { email: user.email }

        expect(response).to have_http_status(:unauthorized)
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

        expect(response).to have_http_status(:temporary_redirect)
        expect(response.location).to include("/auth/saml?account_id=#{account.id}")
      end

      it 'handles email case insensitivity' do
        post '/api/v1/auth/saml_login', params: { email: user.email.upcase }

        expect(response).to have_http_status(:temporary_redirect)
        expect(response.location).to include("/auth/saml?account_id=#{account.id}")
      end

      it 'strips whitespace from email' do
        post '/api/v1/auth/saml_login', params: { email: "  #{user.email}  " }

        expect(response).to have_http_status(:temporary_redirect)
        expect(response.location).to include("/auth/saml?account_id=#{account.id}")
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

        expect(response).to have_http_status(:temporary_redirect)
        returned_account_id = response.location.match(/account_id=(\d+)/)[1].to_i
        expect([account.id, account2.id]).to include(returned_account_id)
      end
    end
  end
end
