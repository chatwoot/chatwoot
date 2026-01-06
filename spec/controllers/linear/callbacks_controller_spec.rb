require 'rails_helper'

RSpec.describe Linear::CallbacksController, type: :request do
  let(:account) { create(:account) }
  let(:code) { SecureRandom.hex(10) }
  let(:client_secret) { 'test_linear_secret' }
  let(:state) { JWT.encode({ sub: account.id, iat: Time.current.to_i }, client_secret, 'HS256') }
  let(:linear_redirect_uri) { "#{ENV.fetch('FRONTEND_URL', '')}/app/accounts/#{account.id}/settings/integrations/linear" }

  describe 'GET /linear/callback' do
    let(:access_token) { SecureRandom.hex(10) }
    let(:response_body) do
      {
        'access_token' => access_token,
        'token_type' => 'Bearer',
        'expires_in' => 7200,
        'scope' => 'read,write'
      }
    end

    before do
      stub_const('ENV', ENV.to_hash.merge('FRONTEND_URL' => 'http://www.example.com'))
      allow(GlobalConfigService).to receive(:load).and_call_original
      allow(GlobalConfigService).to receive(:load).with('LINEAR_CLIENT_SECRET', nil).and_return(client_secret)
      allow(GlobalConfigService).to receive(:load).with('LINEAR_CLIENT_ID', nil).and_return('test_client_id')
    end

    context 'when successful' do
      before do
        stub_request(:post, 'https://api.linear.app/oauth/token')
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'creates a new integration hook' do
        expect do
          get linear_callback_path, params: { code: code, state: state }
        end.to change(Integrations::Hook, :count).by(1)

        hook = Integrations::Hook.last
        expect(hook.access_token).to eq(access_token)
        expect(hook.app_id).to eq('linear')
        expect(hook.status).to eq('enabled')
        expect(hook.settings).to eq(
          'token_type' => 'Bearer',
          'expires_in' => 7200,
          'scope' => 'read,write'
        )
        expect(response).to redirect_to(linear_redirect_uri)
      end
    end

    context 'when the code is missing' do
      before do
        stub_request(:post, 'https://api.linear.app/oauth/token')
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'redirects to the linear_redirect_uri' do
        get linear_callback_path, params: { state: state }
        expect(response).to redirect_to(linear_redirect_uri)
      end
    end

    context 'when the token is invalid' do
      before do
        stub_request(:post, 'https://api.linear.app/oauth/token')
          .to_return(
            status: 400,
            body: { error: 'invalid_grant' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'redirects to the linear_redirect_uri' do
        get linear_callback_path, params: { code: code, state: state }
        expect(response).to redirect_to(linear_redirect_uri)
      end
    end
  end
end
