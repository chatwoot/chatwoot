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

      it 'updates the reusable hook without replacing its identity or unrelated settings' do
        hook = create(
          :integrations_hook,
          :shopify,
          account: account,
          access_token: 'old-access-token',
          settings: { scope: 'read_customers', store_name: 'Acme' }
        )

        expect do
          get shopify_callback_path, params: { code: code, state: state, shop: shop }
        end.not_to change(Integrations::Hook, :count)

        expect(hook.reload).to have_attributes(
          access_token: access_token,
          reference_id: shop,
          status: 'enabled',
          settings: { 'scope' => 'read_products,write_products', 'store_name' => 'Acme' }
        )
      end

      it 'rejects a non-Shopify callback domain before exchanging the authorization code' do
        get shopify_callback_path,
            params: { code: code, state: state, shop: 'my-store.myshopify.com.attacker.example' }

        expect(response).to redirect_to("#{shopify_redirect_uri}?error=true")
        expect(auth_code_strategy).not_to have_received(:get_token)
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

    context 'with a catalog installation state' do
      include_context 'with stubbed account'

      let(:nonce) { SecureRandom.hex(32) }
      let(:state) do
        JWT.encode(
          {
            sub: account.id,
            iat: Time.current.to_i,
            exp: 10.minutes.from_now.to_i,
            aud: 'shopify_oauth',
            installation_id: installation.id,
            nonce: nonce
          },
          'shopify-client-secret',
          'HS256'
        )
      end
      let(:installation) do
        create(
          :captain_tool_catalog_installation,
          account: account,
          initiated_by: create(:user, account: account, role: :administrator),
          provider_key: 'shopify',
          status: 'awaiting_connection',
          oauth_nonce_digest: Digest::SHA256.hexdigest(nonce),
          selected_templates: [
            {
              'template_key' => 'get_current_customer',
              'template_version' => '1.0.0',
              'configuration' => {}
            }
          ]
        )
      end
      let(:pack) do
        compiled = Captain::ToolCatalog::ProviderPackCompiler.new(
          pack_path: Rails.root.join('spec/fixtures/captain/tool_catalog/providers/example')
        ).compile.deep_dup
        compiled['provider']['key'] = 'shopify'
        compiled['templates'].sole['effective_scopes'] = ['read_products']
        compiled['operations'].find { |operation| operation['key'] == 'find_customer' }['scopes'] = ['read_products']
        compiled
      end

      before do
        account.enable_features!('captain_tool_catalog')
        allow(auth_code_strategy).to receive(:get_token).and_return(token_response)
        allow(GlobalConfigService).to receive(:load).with('SHOPIFY_CLIENT_SECRET', nil).and_return('shopify-client-secret')
        allow(Captain::ToolCatalog::ProviderPackRegistry).to receive(:default).and_return(
          instance_double(Captain::ToolCatalog::ProviderPackRegistry, all: [pack], find: pack)
        )
      end

      it 'consumes the nonce once, reuses the hook, and resumes the same installation' do
        get shopify_callback_path, params: { code: code, state: state, shop: shop }

        hook = account.hooks.account_hooks.find_by!(app_id: 'shopify')
        expect(response).to redirect_to(shopify_redirect_uri)
        expect(installation.reload).to be_completed
        expect(installation.oauth_nonce_digest).to be_nil
        expect(installation.integration_hook).to eq(hook)
        expect(installation.resulting_tool_ids).to eq([account.captain_custom_tools.catalog.sole.id])

        get shopify_callback_path, params: { code: code, state: state, shop: shop }

        expect(response).to redirect_to("#{shopify_redirect_uri}?error=true")
        expect(auth_code_strategy).to have_received(:get_token).once
      end
    end

    context 'with a cross-account catalog installation state' do
      let(:other_account) { create(:account) }
      let(:nonce) { SecureRandom.hex(32) }
      let(:installation) do
        create(
          :captain_tool_catalog_installation,
          account: other_account,
          initiated_by: create(:user, account: other_account, role: :administrator),
          provider_key: 'shopify',
          status: 'awaiting_connection',
          oauth_nonce_digest: Digest::SHA256.hexdigest(nonce)
        )
      end
      let(:state) do
        JWT.encode(
          {
            sub: account.id,
            exp: 10.minutes.from_now.to_i,
            aud: 'shopify_oauth',
            installation_id: installation.id,
            nonce: nonce
          },
          'shopify-client-secret',
          'HS256'
        )
      end

      before do
        allow(described_class).to receive(:new).and_wrap_original do |original, *args|
          controller = original.call(*args)
          allow(controller).to receive(:oauth_client).and_return(oauth_client)
          controller
        end
        allow(oauth_client).to receive(:auth_code).and_return(auth_code_strategy)
        allow(auth_code_strategy).to receive(:get_token).and_return(token_response)
        allow(GlobalConfigService).to receive(:load).with('SHOPIFY_CLIENT_SECRET', nil).and_return('shopify-client-secret')
      end

      it 'rejects the state before exchanging the authorization code' do
        get shopify_callback_path, params: { code: code, state: state, shop: shop }

        expect(response).to redirect_to("#{shopify_redirect_uri}?error=true")
        expect(auth_code_strategy).not_to have_received(:get_token)
        expect(installation.reload.oauth_nonce_digest).to eq(Digest::SHA256.hexdigest(nonce))
        expect(account.hooks).to be_empty
      end
    end
  end
end
