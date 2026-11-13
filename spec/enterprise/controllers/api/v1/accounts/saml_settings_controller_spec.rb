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

      context 'with a metadata URL' do
        let(:metadata_url) { 'https://idp.example.com/saml/v2/metadata' }
        let(:certificate) { build(:account_saml_settings).certificate }
        let(:metadata) { { sso_url: 'https://idp.example.com/saml/v2/SSO', idp_entity_id: metadata_url, signing_certificates: [certificate] } }
        let(:metadata_service) { instance_double(Saml::IdpMetadataService, perform: metadata) }

        before do
          allow(Saml::IdpMetadataService).to receive(:new).with(metadata_url).and_return(metadata_service)
        end

        it 'creates SAML settings from the metadata' do
          post "/api/v1/accounts/#{account.id}/saml_settings",
               params: { saml_settings: { metadata_url: metadata_url } },
               headers: administrator.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
          expect(json_response).to include(metadata_url: metadata_url, sso_url: metadata[:sso_url], certificate: certificate)
        end

        it 'returns unprocessable entity when the metadata cannot be read' do
          allow(metadata_service).to receive(:perform).and_raise(Saml::IdpMetadataService::Error.new(:unreachable))

          post "/api/v1/accounts/#{account.id}/saml_settings",
               params: { saml_settings: { metadata_url: metadata_url } },
               headers: administrator.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response[:errors].first).to start_with('Metadata url could not be reached')
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

  describe 'POST /api/v1/accounts/{account.id}/saml_settings/refresh' do
    let(:metadata_url) { 'https://idp.example.com/saml/v2/metadata' }
    let(:certificate) { build(:account_saml_settings).certificate.strip }
    let(:rotated_certificate) { build(:account_saml_settings).certificate.strip }
    let(:metadata) { { sso_url: 'https://idp.example.com/saml/v2/SSO', idp_entity_id: metadata_url, signing_certificates: [certificate] } }
    let(:metadata_service) { instance_double(Saml::IdpMetadataService, perform: metadata) }

    before do
      allow(Saml::IdpMetadataService).to receive(:new).with(metadata_url).and_return(metadata_service)
      AccountSamlSettings.create!(account: account, metadata_url: metadata_url)
    end

    context 'when authenticated as administrator' do
      it 'stores the certificate from the metadata' do
        allow(metadata_service).to receive(:perform).and_return(metadata.merge(signing_certificates: [rotated_certificate]))

        post "/api/v1/accounts/#{account.id}/saml_settings/refresh",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(json_response[:certificate]).to eq(rotated_certificate)
        expect(account.saml_settings.reload.certificate).to eq(rotated_certificate)
      end

      it 'keeps the stored values when the metadata cannot be read' do
        allow(metadata_service).to receive(:perform).and_raise(Saml::IdpMetadataService::Error.new(:unreachable))

        post "/api/v1/accounts/#{account.id}/saml_settings/refresh",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:errors].first).to start_with('Metadata url could not be reached')
        expect(account.saml_settings.reload.certificate).to eq(certificate)
      end

      it 'returns unprocessable entity without a metadata URL' do
        account.saml_settings.update!(metadata_url: nil)

        post "/api/v1/accounts/#{account.id}/saml_settings/refresh",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:errors]).to eq(["Metadata url can't be blank"])
      end
    end

    context 'when authenticated as agent' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/saml_settings/refresh",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
