require 'rails_helper'

RSpec.describe Shopify::CallbacksController, type: :request do
  let(:account) { create(:account) }
  let(:code) { SecureRandom.hex(10) }
  let(:state) { SecureRandom.hex(10) }
  let(:shop) { 'my-store.myshopify.com' }
  let(:client_secret) { 'test_secret_key_1234567890' }
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

  # Helper to compute HMAC for test requests (matches Shopify's algorithm)
  def compute_hmac(params, secret)
    query_string = params.except(:hmac).sort.map { |k, v| "#{k}=#{v}" }.join('&')
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('SHA256'), secret, query_string)
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
      account.enable_features!('shopify_integration')
      allow(GlobalConfigService).to receive(:load)
        .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
        .and_return(true)
    end

    shared_context 'with stubbed account' do
      before do
        allow(described_class).to receive(:new).and_wrap_original do |original, *args|
          controller = original.call(*args)
          allow(controller).to receive(:verify_shopify_token).and_return(account.id)
          allow(controller).to receive(:oauth_client).and_return(oauth_client)
          allow(controller).to receive(:client_secret).and_return(client_secret)
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
        params = { code: code, state: state, shop: shop }
        params[:hmac] = compute_hmac(params, client_secret)

        expect do
          get shopify_callback_path, params: params
        end.to change(Integrations::Hook, :count).by(1)

        hook = Integrations::Hook.last
        expect(hook.access_token).to eq(access_token)
        expect(hook.app_id).to eq('shopify')
        expect(hook.status).to eq('enabled')
        expect(hook.reference_id).to eq(shop)
        expect(hook.settings).to include(
          'scope' => 'read_products,write_products',
          'connected_at' => be_present,
          'installation_id' => match(/\A[0-9a-f-]{36}\z/)
        )
        expect(response).to redirect_to(shopify_redirect_uri)
      end
    end

    context 'when the account feature is disabled' do
      include_context 'with stubbed account'

      before do
        account.disable_features('shopify_integration')
      end

      it 'does not exchange the OAuth code or create a hook' do
        params = { code: code, state: state, shop: shop }
        params[:hmac] = compute_hmac(params, client_secret)

        expect(auth_code_strategy).not_to receive(:get_token)

        expect do
          get shopify_callback_path, params: params
        end.not_to change(Integrations::Hook, :count)

        expect(response).to redirect_to("#{shopify_redirect_uri}?error=true")
      end
    end

    context 'when the installation switch is disabled' do
      before do
        allow(described_class).to receive(:new).and_wrap_original do |original, *args|
          controller = original.call(*args)
          allow(controller).to receive(:verify_shopify_token).and_return(nil)
          controller
        end
        allow(GlobalConfigService).to receive(:load)
          .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
          .and_return(false)
      end

      it 'does not exchange the OAuth code or store a pending install' do
        params = { code: code, state: state, shop: shop }
        params[:hmac] = compute_hmac(params, client_secret)

        expect(OAuth2::Client).not_to receive(:new)
        expect(Shopify::PendingInstallation).not_to receive(:create)

        get shopify_callback_path, params: params

        expect(response).to redirect_to("#{frontend_url}?error=true")
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
        params = { state: state, shop: shop }
        params[:hmac] = compute_hmac(params, client_secret)

        get shopify_callback_path, params: params
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
        params = { code: code, state: state, shop: shop }
        params[:hmac] = compute_hmac(params, client_secret)

        get shopify_callback_path, params: params
        expect(response).to redirect_to("#{shopify_redirect_uri}?error=true")
      end
    end

    context 'when state parameter is invalid' do
      before do
        # rubocop:disable RSpec/AnyInstance, RSpec/DescribedClass
        # Explicit class name and any_instance required for parallel CI stability
        allow_any_instance_of(Shopify::CallbacksController).to receive(:verify_shopify_token).and_return(nil)
        allow_any_instance_of(Shopify::CallbacksController).to receive(:oauth_client).and_return(oauth_client)
        allow_any_instance_of(Shopify::CallbacksController).to receive(:client_secret).and_return(client_secret)
        # rubocop:enable RSpec/AnyInstance, RSpec/DescribedClass
        allow(oauth_client).to receive(:auth_code).and_return(auth_code_strategy)
        allow(auth_code_strategy).to receive(:get_token).and_return(token_response)
      end

      it 'handles as Shopify-initiated install and redirects to signup with pending install token' do
        params = { code: code, state: state, shop: shop }
        params[:hmac] = compute_hmac(params, client_secret)
        pending_install_token = SecureRandom.hex(16)

        expect(Shopify::PendingInstallation).to receive(:create).with(
          access_token: access_token,
          shop: shop,
          scope: 'read_products,write_products'
        ).and_return(pending_install_token)

        get shopify_callback_path, params: params
        expect(response).to redirect_to(
          "#{frontend_url}/app/auth/signup?shopify_pending_install=#{pending_install_token}"
        )
      end
    end

    context 'when a Shopify-billed account is reinstalled' do
      let(:shopify_account) do
        create(
          :account,
          internal_attributes: {
            'billing_provider' => 'shopify',
            'signup_source' => 'shopify'
          },
          custom_attributes: {
            'subscription_status' => 'expired',
            'shopify_subscription_snapshot' => {
              'state' => 'expired',
              'plan_handles' => [],
              'shop_domain' => shop
            }
          }
        )
      end

      before do
        shopify_account.enable_features!('shopify_integration')
        allow(described_class).to receive(:new).and_wrap_original do |original, *args|
          controller = original.call(*args)
          allow(controller).to receive(:verify_shopify_token).and_return(nil)
          allow(controller).to receive(:oauth_client).and_return(oauth_client)
          allow(controller).to receive(:client_secret).and_return(client_secret)
          controller
        end
        allow(oauth_client).to receive(:auth_code).and_return(auth_code_strategy)
        allow(auth_code_strategy).to receive(:get_token).and_return(token_response)
      end

      it 'reactivates a retained hook and redirects to billing' do
        previous_installation_id = SecureRandom.uuid
        hook = create(
          :integrations_hook,
          :shopify,
          account: shopify_account,
          reference_id: shop,
          status: :disabled,
          access_token: nil,
          settings: {
            'connected_at' => 1.day.ago.utc.iso8601(6),
            'installation_id' => previous_installation_id
          }
        )
        params = { code: code, state: state, shop: shop }
        params[:hmac] = compute_hmac(params, client_secret)

        expect(Shopify::PendingInstallation).not_to receive(:create)

        get shopify_callback_path, params: params

        expect(hook.reload).to have_attributes(
          status: 'enabled',
          access_token: access_token
        )
        expect(hook.settings).to include(
          'scope' => 'read_products,write_products',
          'connected_at' => be_present,
          'installation_id' => match(/\A[0-9a-f-]{36}\z/)
        )
        expect(hook.settings['installation_id']).not_to eq(previous_installation_id)
        expect(response).to redirect_to(
          "#{frontend_url}/app/accounts/#{shopify_account.id}/settings/billing?shop=#{shop}"
        )
      end

      it 'recreates the hook from the retained billing snapshot after privacy cleanup' do
        params = { code: code, state: state, shop: shop }
        params[:hmac] = compute_hmac(params, client_secret)

        expect do
          get shopify_callback_path, params: params
        end.to change { shopify_account.hooks.where(app_id: 'shopify').count }.by(1)

        recreated_hook = shopify_account.hooks.find_by!(app_id: 'shopify')
        expect(recreated_hook).to have_attributes(
          status: 'enabled',
          access_token: access_token,
          reference_id: shop
        )
        expect(recreated_hook.settings).to include(
          'scope' => 'read_products,write_products',
          'connected_at' => be_present,
          'installation_id' => match(/\A[0-9a-f-]{36}\z/)
        )
        expect(response).to redirect_to(
          "#{frontend_url}/app/accounts/#{shopify_account.id}/settings/billing?shop=#{shop}"
        )
      end

      it 'recreates a hook deleted while the OAuth code is being exchanged' do
        hook = create(
          :integrations_hook,
          :shopify,
          account: shopify_account,
          reference_id: shop,
          status: :disabled,
          access_token: nil
        )
        allow(auth_code_strategy).to receive(:get_token) do
          hook.destroy!
          token_response
        end
        params = { code: code, state: state, shop: shop }
        params[:hmac] = compute_hmac(params, client_secret)

        get shopify_callback_path, params: params

        replacement_hook = shopify_account.hooks.find_by!(app_id: 'shopify')
        expect(replacement_hook.id).not_to eq(hook.id)
        expect(replacement_hook).to have_attributes(
          status: 'enabled',
          access_token: access_token,
          reference_id: shop
        )
        expect(response).to redirect_to(
          "#{frontend_url}/app/accounts/#{shopify_account.id}/settings/billing?shop=#{shop}"
        )
      end

      it 'recreates a hook deleted while the reconnect lock is being acquired' do
        hook = create(
          :integrations_hook,
          :shopify,
          account: shopify_account,
          reference_id: shop,
          status: :disabled,
          access_token: nil
        )
        deleted = false
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Integrations::Hook).to receive(:with_lock).and_wrap_original do |original, *args, &block|
          if original.receiver.id == hook.id && !deleted
            deleted = true
            hook.delete
            raise ActiveRecord::RecordNotFound
          end

          original.call(*args, &block)
        end
        # rubocop:enable RSpec/AnyInstance
        params = { code: code, state: state, shop: shop }
        params[:hmac] = compute_hmac(params, client_secret)

        get shopify_callback_path, params: params

        replacement_hook = shopify_account.hooks.find_by!(app_id: 'shopify')
        expect(replacement_hook.id).not_to eq(hook.id)
        expect(replacement_hook).to have_attributes(
          status: 'enabled',
          access_token: access_token,
          reference_id: shop
        )
        expect(response).to redirect_to(
          "#{frontend_url}/app/accounts/#{shopify_account.id}/settings/billing?shop=#{shop}"
        )
      end

      it 'does not exchange the OAuth code when the account feature is disabled' do
        create(:integrations_hook, :shopify, account: shopify_account, reference_id: shop)
        shopify_account.disable_features!('shopify_integration')
        params = { code: code, state: state, shop: shop }
        params[:hmac] = compute_hmac(params, client_secret)

        expect(auth_code_strategy).not_to receive(:get_token)

        get shopify_callback_path, params: params

        expect(response).to redirect_to(
          "#{frontend_url}/app/accounts/#{shopify_account.id}/settings/integrations/shopify?error=true"
        )
      end
    end

    context 'when cleanup completes during the OAuth exchange' do
      before do
        allow(described_class).to receive(:new).and_wrap_original do |original, *args|
          controller = original.call(*args)
          allow(controller).to receive(:verify_shopify_token).and_return(nil)
          allow(controller).to receive(:oauth_client).and_return(oauth_client)
          allow(controller).to receive(:client_secret).and_return(client_secret)
          controller
        end
        allow(oauth_client).to receive(:auth_code).and_return(auth_code_strategy)
      end

      it 'does not restore the hook from the older callback' do
        hook = create(:integrations_hook, :shopify, account: account, reference_id: shop)
        allow(auth_code_strategy).to receive(:get_token) do
          Shopify::UninstallationService.new(hook: hook, occurred_at: Time.current).perform
          token_response
        end
        params = { code: code, state: state, shop: shop }
        params[:hmac] = compute_hmac(params, client_secret)

        get shopify_callback_path, params: params

        expect(account.hooks.where(app_id: 'shopify')).to be_empty
        expect(response).to redirect_to("#{shopify_redirect_uri}?error=true")
      end
    end
  end
end
