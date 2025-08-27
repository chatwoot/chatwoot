require 'rails_helper'

RSpec.describe Api::V1::Accounts::Saml::CallbacksController, type: :controller do
  let(:account) { create(:account) }
  let(:saml_settings) { create(:account_saml_settings, :enabled, account: account) }

  describe 'POST #create' do
    before do
      allow(AccountSamlSettings).to receive(:find_by).and_return(saml_settings)
    end

    context 'when SAML response is received' do
      let(:saml_response) { Base64.encode64('<SAMLResponse>dummy</SAMLResponse>') }
      let(:relay_state) { "/app/accounts/#{account.id}/dashboard" }

      it 'receives the SAML response' do
        post :create, params: {
          account_id: account.id,
          SAMLResponse: saml_response,
          RelayState: relay_state
        }

        expect(response).to have_http_status(:ok)
      end

      it 'loads the correct account SAML settings' do
        expect(AccountSamlSettings).to receive(:find_by).with(account_id: account.id, enabled: true)

        post :create, params: {
          account_id: account.id,
          SAMLResponse: saml_response,
          RelayState: relay_state
        }
      end

      it 'returns SAML settings in response' do
        post :create, params: {
          account_id: account.id,
          SAMLResponse: saml_response,
          RelayState: relay_state
        }

        json_response = JSON.parse(response.body)
        expect(json_response['saml_settings']).to include(
          'sp_entity_id' => saml_settings.sp_entity_id_or_default,
          'enabled' => true,
          'sso_url' => saml_settings.sso_url,
          'certificate_fingerprint' => saml_settings.certificate_fingerprint,
          'enforced_sso' => saml_settings.enforced_sso,
          'attribute_mappings' => saml_settings.attribute_mappings,
          'role_mappings' => saml_settings.role_mappings
        )
      end

      it 'includes received SAML data in response' do
        post :create, params: {
          account_id: account.id,
          SAMLResponse: saml_response,
          RelayState: relay_state
        }

        json_response = JSON.parse(response.body)
        expect(json_response['received_data']).to include(
          'saml_response' => saml_response,
          'relay_state' => relay_state
        )
      end
    end

    context 'when SAML is not enabled for account' do
      before do
        allow(AccountSamlSettings).to receive(:find_by).and_return(nil)
      end

      it 'returns not found error' do
        post :create, params: {
          account_id: account.id,
          SAMLResponse: 'dummy'
        }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('SAML not enabled for this account')
      end
    end

    context 'when account does not exist' do
      it 'returns not found error' do
        post :create, params: {
          account_id: 0,
          SAMLResponse: 'dummy'
        }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET #sso' do
    before do
      allow(AccountSamlSettings).to receive(:find_by).and_return(saml_settings)
    end

    context 'when initiating SSO' do
      it 'returns SSO configuration' do
        get :sso, params: { account_id: account.id }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to include(
          'sso_url' => saml_settings.sso_url,
          'sp_entity_id' => saml_settings.sp_entity_id_or_default,
          'acs_url' => "http://test.host/api/v1/accounts/#{account.id}/saml/callback"
        )
      end
    end

    context 'when SAML is not enabled' do
      before do
        allow(AccountSamlSettings).to receive(:find_by).and_return(nil)
      end

      it 'returns not found error' do
        get :sso, params: { account_id: account.id }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
