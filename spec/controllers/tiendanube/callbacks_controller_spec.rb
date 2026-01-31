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
    allow(ENV).to receive(:fetch).with('FRONTEND_URL', nil).and_return('http://localhost:3000')
  end

  describe 'GET #show' do
    context 'with valid OAuth callback' do
      let(:state) { JWT.encode({ sub: account.id, iat: Time.current.to_i }, client_secret, 'HS256') }
      let(:oauth_response) do
        double(
          response: double(
            parsed: {
              'access_token' => access_token,
              'user_id' => user_id,
              'scope' => 'read_customers read_orders'
            }
          )
        )
      end

      before do
        allow_any_instance_of(OAuth2::Client).to receive_message_chain(:auth_code, :get_token).and_return(oauth_response)
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

      before do
        allow_any_instance_of(OAuth2::Client).to receive_message_chain(:auth_code, :get_token).and_raise(StandardError, 'OAuth error')
      end

      it 'redirects with error' do
        get :show, params: { code: 'auth_code', state: state, store_id: store_id }
        expect(response).to redirect_to("http://localhost:3000/app/accounts/#{account.id}/settings/integrations/tiendanube?error=true")
      end
    end
  end
end
