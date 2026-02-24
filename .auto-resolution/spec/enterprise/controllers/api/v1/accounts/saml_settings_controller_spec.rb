# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::SamlSettings', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:administrator) { create(:user, account: account, role: :administrator) }

  before do
    account.enable_features('saml')
    account.save!
  end

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe 'GET /api/v1/accounts/{account.id}/saml_settings' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/saml_settings"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as administrator' do
      context 'when SAML settings exist' do
        let(:saml_settings) do
          create(:account_saml_settings,
                 account: account,
                 sso_url: 'https://idp.example.com/saml/sso',
                 role_mappings: { 'Admins' => { 'role' => 1 } })
        end

        before do
          saml_settings # Ensure the record exists
        end

        it 'returns the SAML settings' do
          get "/api/v1/accounts/#{account.id}/saml_settings",
              headers: administrator.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          expect(json_response[:sso_url]).to eq('https://idp.example.com/saml/sso')
          expect(json_response[:role_mappings]).to eq({ Admins: { role: 1 } })
        end
      end

      context 'when SAML settings do not exist' do
        it 'returns default SAML settings' do
          get "/api/v1/accounts/#{account.id}/saml_settings",
              headers: administrator.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          expect(json_response[:role_mappings]).to eq({})
        end
      end
    end

    context 'when authenticated as agent' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/saml_settings",
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when SAML feature is not enabled' do
      before do
        account.disable_features('saml')
        account.save!
      end

      it 'returns forbidden with feature not enabled message' do
        get "/api/v1/accounts/#{account.id}/saml_settings",
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/saml_settings' do
    let(:valid_params) do
      key = OpenSSL::PKey::RSA.new(2048)
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 1
      cert.subject = OpenSSL::X509::Name.parse('/C=US/ST=Test/L=Test/O=Test/CN=test.example.com')
      cert.issuer = cert.subject
      cert.public_key = key.public_key
      cert.not_before = Time.zone.now
      cert.not_after = cert.not_before + (365 * 24 * 60 * 60)
      cert.sign(key, OpenSSL::Digest.new('SHA256'))

      {
        saml_settings: {
          sso_url: 'https://idp.example.com/saml/sso',
          certificate: cert.to_pem,
          idp_entity_id: 'https://idp.example.com/saml/metadata',
          role_mappings: { 'Admins' => { 'role' => 1 }, 'Users' => { 'role' => 0 } }
        }
      }
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/saml_settings", params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as administrator' do
      context 'with valid parameters' do
        it 'creates SAML settings' do
          expect do
            post "/api/v1/accounts/#{account.id}/saml_settings",
                 params: valid_params,
                 headers: administrator.create_new_auth_token,
                 as: :json
          end.to change(AccountSamlSettings, :count).by(1)

          expect(response).to have_http_status(:success)

          saml_settings = AccountSamlSettings.find_by(account: account)
          expect(saml_settings.sso_url).to eq('https://idp.example.com/saml/sso')
          expect(saml_settings.role_mappings).to eq({ 'Admins' => { 'role' => 1 }, 'Users' => { 'role' => 0 } })
        end
      end

      context 'with invalid parameters' do
        let(:invalid_params) do
          valid_params.tap do |params|
            params[:saml_settings][:sso_url] = nil
          end
        end

        it 'returns unprocessable entity' do
          post "/api/v1/accounts/#{account.id}/saml_settings",
               params: invalid_params,
               headers: administrator.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(AccountSamlSettings.count).to eq(0)
        end
      end
    end

    context 'when authenticated as agent' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/saml_settings",
             params: valid_params,
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
        expect(AccountSamlSettings.count).to eq(0)
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/saml_settings' do
    let(:saml_settings) do
      create(:account_saml_settings,
             account: account,
             sso_url: 'https://old.example.com/saml')
    end
    let(:update_params) do
      key = OpenSSL::PKey::RSA.new(2048)
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 3
      cert.subject = OpenSSL::X509::Name.parse('/C=US/ST=Test/L=Test/O=Test/CN=update.example.com')
      cert.issuer = cert.subject
      cert.public_key = key.public_key
      cert.not_before = Time.zone.now
      cert.not_after = cert.not_before + (365 * 24 * 60 * 60)
      cert.sign(key, OpenSSL::Digest.new('SHA256'))

      {
        saml_settings: {
          sso_url: 'https://new.example.com/saml/sso',
          certificate: cert.to_pem,
          role_mappings: { 'NewGroup' => { 'custom_role_id' => 5 } }
        }
      }
    end

    before do
      saml_settings # Ensure the record exists
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/saml_settings", params: update_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as administrator' do
      it 'updates SAML settings' do
        put "/api/v1/accounts/#{account.id}/saml_settings",
            params: update_params,
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        saml_settings.reload
        expect(saml_settings.sso_url).to eq('https://new.example.com/saml/sso')
        expect(saml_settings.role_mappings).to eq({ 'NewGroup' => { 'custom_role_id' => 5 } })
      end
    end

    context 'when authenticated as agent' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/saml_settings",
            params: update_params,
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/saml_settings' do
    let(:saml_settings) { create(:account_saml_settings, account: account) }

    before do
      saml_settings # Ensure the record exists
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/saml_settings"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as administrator' do
      it 'destroys SAML settings' do
        expect do
          delete "/api/v1/accounts/#{account.id}/saml_settings",
                 headers: administrator.create_new_auth_token
        end.to change(AccountSamlSettings, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when authenticated as agent' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/saml_settings",
               headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
        expect(AccountSamlSettings.count).to eq(1)
      end
    end
  end
end
