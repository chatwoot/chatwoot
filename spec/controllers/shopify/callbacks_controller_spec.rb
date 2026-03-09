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
  let(:token_response) do
    instance_double(
      OAuth2::AccessToken,
      response: instance_double(OAuth2::Response, parsed: response_body),
      token: access_token
    )
  end

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

    shared_context 'with stubbed account' do
      before do
        allow(described_class).to receive(:new).and_wrap_original do |original, *args|
          controller = original.call(*args)
          allow(controller).to receive(:verify_shopify_token).and_return(account.id)
          allow(controller).to receive(:oauth_client).and_return(oauth_client)
          controller
        end
        allow(Account).to receive(:find).and_return(account)

        allow(oauth_client).to receive(:auth_code).and_return(auth_code_strategy)
      end
    end

    context 'when successful' do
      include_context 'with stubbed account'
      before do
        allow(auth_code_strategy).to receive(:get_token).and_return(token_response)
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
      include_context 'with stubbed account'
      before do
        allow(auth_code_strategy).to receive(:get_token).and_raise(StandardError)
        stub_request(:post, "https://#{shop}/admin/oauth/access_token")
          .to_return(status: 400, body: { error: 'invalid_grant' }.to_json)
      end

      it 'redirects to the shopify_redirect_uri with error' do
        get shopify_callback_path, params: { state: state, shop: shop }
        expect(response).to redirect_to("#{shopify_redirect_uri}?error=true")
      end
    end

    context 'when the token is invalid' do
      include_context 'with stubbed account'
      before do
        allow(auth_code_strategy).to receive(:get_token).and_raise(
          OAuth2::Error.new(
            OpenStruct.new(
              parsed: { 'error' => 'invalid_grant' },
              status: 400
            )
          )
        )

        stub_request(:post, "https://#{shop}/admin/oauth/access_token")
          .to_return(status: 400, body: { error: 'invalid_grant' }.to_json)
      end

      it 'redirects to the shopify_redirect_uri with error' do
        get shopify_callback_path, params: { code: code, state: state, shop: shop }
        expect(response).to redirect_to("#{shopify_redirect_uri}?error=true")
      end
    end

    context 'when state parameter is invalid' do
      before do
        # rubocop:disable RSpec/AnyInstance, RSpec/DescribedClass
        # Explicit class name and any_instance required for parallel CI stability
        allow_any_instance_of(Shopify::CallbacksController).to receive(:verify_shopify_token).and_return(nil)
        allow_any_instance_of(Shopify::CallbacksController).to receive(:account).and_return(nil)
        # rubocop:enable RSpec/AnyInstance, RSpec/DescribedClass
      end

      it 'redirects to the frontend URL with error' do
        get shopify_callback_path, params: { code: code, state: state, shop: shop }
        expect(response).to redirect_to("#{frontend_url}?error=true")
      end
    end
  end
end
