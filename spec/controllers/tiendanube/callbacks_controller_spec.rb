require 'rails_helper'

RSpec.describe Tiendanube::CallbacksController, type: :controller do
  let(:account) { create(:account) }
  let(:client_id) { 'test_client_id' }
  let(:client_secret) { 'test_client_secret' }
  let(:store_id) { '123456' }
  let(:access_token) { 'test_access_token' }
  let(:user_id) { '789' }

  before do
    allow(GlobalConfigService).to receive(:load).with('TIENDANUBE_CLIENT_ID', nil).and_return(client_id)
    allow(GlobalConfigService).to receive(:load).with('TIENDANUBE_CLIENT_SECRET', nil).and_return(client_secret)
  end

  around do |example|
    with_modified_env FRONTEND_URL: 'http://localhost:3000', HELPCENTER_URL: 'http://localhost:3000' do
      example.run
    end
  end

  describe 'GET #show' do
    context 'with valid OAuth callback' do
      let(:state) { JWT.encode({ sub: account.id, iat: Time.current.to_i }, client_secret, 'HS256') }
      let(:parsed_body) do
        {
          'access_token' => access_token,
          'user_id' => user_id,
          'scope' => 'read_customers read_orders'
        }
      end
      let(:oauth_response) do
        instance_double(
          OAuth2::AccessToken,
          response: instance_double(OAuth2::Response, parsed: parsed_body)
        )
      end
      let(:auth_code_strategy) { instance_double(OAuth2::Strategy::AuthCode, get_token: oauth_response) }
      let(:oauth_client) { instance_double(OAuth2::Client, auth_code: auth_code_strategy) }

      before do
        allow(controller).to receive(:oauth_client).and_return(oauth_client)
      end

      it 'creates a new integration hook' do
        expect do
          get :show, params: { code: 'auth_code', state: state, store_id: store_id }
        end.to change(Integrations::Hook, :count).by(1)
      end

      it 'stores the correct hook data' do
        get :show, params: { code: 'auth_code', state: state, store_id: store_id }
        hook = Integrations::Hook.last
        expect(hook.app_id).to eq('tiendanube')
        expect(hook.access_token).to eq(access_token)
        expect(hook.reference_id).to eq(user_id.to_s)
        expect(hook.account_id).to eq(account.id)
      end

      it 'redirects to the integration settings page' do
        get :show, params: { code: 'auth_code', state: state, store_id: store_id }
        expect(response).to redirect_to("http://localhost:3000/app/accounts/#{account.id}/settings/integrations/tiendanube")
      end
    end

    context 'with invalid state parameter' do
      it 'redirects with error' do
        get :show, params: { code: 'auth_code', state: 'invalid_state', store_id: store_id }
        expect(response).to redirect_to('http://localhost:3000?error=true')
      end
    end

    context 'when OAuth exchange fails' do
      let(:state) { JWT.encode({ sub: account.id, iat: Time.current.to_i }, client_secret, 'HS256') }
      let(:auth_code_strategy) { instance_double(OAuth2::Strategy::AuthCode) }
      let(:oauth_client) { instance_double(OAuth2::Client, auth_code: auth_code_strategy) }

      before do
        allow(controller).to receive(:oauth_client).and_return(oauth_client)
        allow(auth_code_strategy).to receive(:get_token).and_raise(StandardError, 'OAuth error')
      end

      it 'redirects with error' do
        get :show, params: { code: 'auth_code', state: state, store_id: store_id }
        expect(response).to redirect_to("http://localhost:3000/app/accounts/#{account.id}/settings/integrations/tiendanube?error=true")
      end
    end
  end
end
