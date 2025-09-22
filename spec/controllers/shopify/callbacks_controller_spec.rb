require 'rails_helper'

RSpec.describe Shopify::CallbacksController, type: :request do
  let(:account) { create(:account) }
  let(:code) { SecureRandom.hex(10) }
  let(:state) { SecureRandom.hex(10) }
  let(:shop) { 'my-store.myshopify.com' }
  let(:frontend_url) { 'http://www.example.com' }
  let(:shopify_redirect_uri) { "#{frontend_url}/app/accounts/#{account.id}/settings/integrations/shopify" }
  let(:oauth_client) { instance_double(OAuth2::Client) }
  let(:auth_code_strategy) { instance_double(OAuth2::Strategy::AuthCode) }

  describe 'GET /shopify/callback' do
    let(:access_token) { SecureRandom.hex(10) }
    let(:response_body) do
      {
        'access_token' => access_token,
        'scope' => 'read_products,write_products'
      }
    end

    before do
      stub_const('ENV', ENV.to_hash.merge('FRONTEND_URL' => frontend_url))
    end

    context 'when successful' do
      before do
        controller = described_class.new
        allow(controller).to receive(:verify_shopify_token).with(state).and_return(account.id)
        allow(described_class).to receive(:new).and_return(controller)

        stub_request(:post, "https://#{shop}/admin/oauth/access_token")
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'creates a new integration hook' do
        expect do
          get shopify_callback_path, params: { code: code, state: state, shop: shop }
        end.to change(Integrations::Hook, :count).by(1)

        hook = Integrations::Hook.last
        expect(hook.access_token).to eq(access_token)
        expect(hook.app_id).to eq('shopify')
        expect(hook.status).to eq('enabled')
        expect(hook.reference_id).to eq(shop)
        expect(hook.settings).to eq(
          'scope' => 'read_products,write_products'
        )
        expect(response).to redirect_to(shopify_redirect_uri)
      end
    end

    context 'when the code is missing' do
      before do
        controller = described_class.new
        allow(controller).to receive(:verify_shopify_token).with(state).and_return(account.id)
        allow(controller).to receive(:oauth_client).and_return(oauth_client)
        allow(oauth_client).to receive(:auth_code).and_raise(StandardError)
        allow(described_class).to receive(:new).and_return(controller)
      end

      it 'redirects to the shopify_redirect_uri with error' do
        get shopify_callback_path, params: { state: state, shop: shop }
        expect(response).to redirect_to("#{shopify_redirect_uri}?error=true")
      end
    end

    context 'when the token is invalid' do
      before do
        controller = described_class.new
        allow(controller).to receive(:verify_shopify_token).with(state).and_return(account.id)
        allow(controller).to receive(:oauth_client).and_return(oauth_client)
        allow(oauth_client).to receive(:auth_code).and_return(auth_code_strategy)
        allow(auth_code_strategy).to receive(:get_token).and_raise(
          OAuth2::Error.new(
            OpenStruct.new(
              parsed: { 'error' => 'invalid_grant' },
              status: 400
            )
          )
        )
        allow(described_class).to receive(:new).and_return(controller)
      end

      it 'redirects to the shopify_redirect_uri with error' do
        get shopify_callback_path, params: { code: code, state: state, shop: shop }
        expect(response).to redirect_to("#{shopify_redirect_uri}?error=true")
      end
    end

    context 'when state parameter is invalid' do
      before do
        controller = described_class.new
        allow(controller).to receive(:verify_shopify_token).with(state).and_return(nil)
        allow(controller).to receive(:account).and_return(nil)
        allow(described_class).to receive(:new).and_return(controller)
      end

      it 'redirects to the frontend URL with error' do
        get shopify_callback_path, params: { code: code, state: state, shop: shop }
        expect(response).to redirect_to("#{frontend_url}?error=true")
      end
    end
  end
end
