require 'rails_helper'

RSpec.describe 'Enterprise Billing Provider APIs', type: :request do
  let(:stripe_account) do
    create(
      :account,
      custom_attributes: {
        'plan_name' => 'Business',
        'stripe_customer_id' => 'cus_test',
        'subscription_status' => 'active',
        'subscription_ends_on' => '2026-08-29T10:00:00Z',
        'billing_currency' => 'usd'
      }
    )
  end
  let!(:stripe_admin) { create(:user, account: stripe_account, role: :administrator) }

  let(:shopify_snapshot) do
    {
      'state' => 'trialing',
      'plan_handles' => ['shopify-basic'],
      'plan_name' => 'Shopify Basic',
      'amount' => '29.00',
      'currency' => 'USD',
      'billing_period' => 'ANNUAL',
      'trial_ends_at' => '2026-08-05T10:00:00Z',
      'current_period_end' => '2026-08-29T10:00:00Z',
      'verified_at' => '2026-07-29T10:00:00Z'
    }
  end
  let(:shopify_account) do
    create(
      :account,
      internal_attributes: {
        'billing_provider' => 'shopify',
        'signup_source' => 'shopify'
      },
      custom_attributes: {
        'plan_name' => 'Shopify Basic',
        'subscription_status' => 'trialing',
        'billing_currency' => 'USD',
        'shopify_subscription_snapshot' => shopify_snapshot,
        'shopify_subscription_verified_at' => shopify_snapshot['verified_at']
      }
    ).tap { |account| account.enable_features(Shopify::FeatureGate::ACCOUNT_FEATURE) }
  end
  let!(:shopify_admin) { create(:user, account: shopify_account, role: :administrator) }
  let!(:shopify_agent) { create(:user, account: shopify_account, role: :agent) }

  before do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    allow(Shopify::FeatureGate).to receive(:enabled?).with(account: shopify_account).and_return(true)
  end

  describe 'GET /enterprise/api/v1/accounts/{account.id}/billing_summary' do
    it 'returns a normalized Stripe summary without changing the existing subscription' do
      get "/enterprise/api/v1/accounts/#{stripe_account.id}/billing_summary",
          headers: stripe_admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'provider' => 'stripe',
        'state' => 'active',
        'plan' => { 'name' => 'Business' },
        'amount' => nil,
        'currency' => 'USD',
        'billing_period' => nil,
        'trial_ends_at' => nil,
        'current_period_end' => '2026-08-29T10:00:00Z',
        'allowed_actions' => {
          'start_subscription' => false,
          'manage_subscription' => true,
          'select_billing_currency' => false,
          'purchase_credits' => true
        },
        'last_verified_at' => nil
      )
    end

    it 'returns the resolved Stripe currency when no currency attribute is stored' do
      stripe_account.update!(
        custom_attributes: stripe_account.custom_attributes.except('billing_currency')
      )

      get "/enterprise/api/v1/accounts/#{stripe_account.id}/billing_summary",
          headers: stripe_admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['currency']).to eq('USD')
    end

    it 'returns a normalized Shopify summary from the last verified snapshot' do
      get "/enterprise/api/v1/accounts/#{shopify_account.id}/billing_summary",
          headers: shopify_admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'provider' => 'shopify',
        'state' => 'trialing',
        'plan' => { 'name' => 'Shopify Basic', 'handle' => 'shopify-basic' },
        'amount' => '29.00',
        'currency' => 'USD',
        'billing_period' => 'ANNUAL',
        'trial_ends_at' => '2026-08-05T10:00:00Z',
        'current_period_end' => '2026-08-29T10:00:00Z',
        'allowed_actions' => {
          'start_subscription' => false,
          'manage_subscription' => true,
          'select_billing_currency' => false,
          'purchase_credits' => false
        },
        'last_verified_at' => '2026-07-29T10:00:00Z'
      )
    end

    it 'forces Shopify verification when requested' do
      refreshed_snapshot = Shopify::SubscriptionSnapshot.from_h(
        shopify_snapshot.merge(
          'state' => 'active',
          'trial_ends_at' => nil,
          'verified_at' => '2026-07-29T11:00:00Z'
        )
      )
      sync_service = instance_double(Enterprise::Billing::ShopifySubscriptionSyncService)
      allow(Enterprise::Billing::ShopifySubscriptionSyncService).to receive(:new).with(account: shopify_account).and_return(sync_service)
      allow(sync_service).to receive(:perform) do
        shopify_account.update!(
          custom_attributes: shopify_account.custom_attributes.merge(
            'shopify_subscription_snapshot' => refreshed_snapshot.to_h,
            'subscription_status' => refreshed_snapshot.state
          )
        )
        refreshed_snapshot
      end

      get "/enterprise/api/v1/accounts/#{shopify_account.id}/billing_summary",
          headers: shopify_admin.create_new_auth_token,
          params: { refresh: true },
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'provider' => 'shopify',
        'state' => 'active',
        'last_verified_at' => '2026-07-29T11:00:00Z'
      )
      expect(sync_service).to have_received(:perform)
    end

    it 'returns the newest persisted snapshot when concurrent refreshes overlap' do
      refreshed_snapshot = Shopify::SubscriptionSnapshot.from_h(
        shopify_snapshot.merge(
          'state' => 'active',
          'verified_at' => '2026-07-29T11:00:00Z'
        )
      )
      newer_snapshot = Shopify::SubscriptionSnapshot.from_h(
        shopify_snapshot.merge(
          'state' => 'cancelled',
          'verified_at' => '2026-07-29T12:00:00Z'
        )
      )
      sync_service = instance_double(Enterprise::Billing::ShopifySubscriptionSyncService)
      allow(Enterprise::Billing::ShopifySubscriptionSyncService).to receive(:new).with(account: shopify_account).and_return(sync_service)
      allow(sync_service).to receive(:perform) do
        shopify_account.update!(
          custom_attributes: shopify_account.custom_attributes.merge(
            'shopify_subscription_snapshot' => newer_snapshot.to_h,
            'subscription_status' => newer_snapshot.state
          )
        )
        refreshed_snapshot
      end

      get "/enterprise/api/v1/accounts/#{shopify_account.id}/billing_summary",
          headers: shopify_admin.create_new_auth_token,
          params: { refresh: true },
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'state' => 'cancelled',
        'last_verified_at' => '2026-07-29T12:00:00Z'
      )
    end

    it 'returns service unavailable when Shopify verification fails' do
      sync_service = instance_double(Enterprise::Billing::ShopifySubscriptionSyncService)
      allow(Enterprise::Billing::ShopifySubscriptionSyncService).to receive(:new).with(account: shopify_account).and_return(sync_service)
      allow(sync_service).to receive(:perform).and_raise(Shopify::PartnerClient::ProviderError, 'Shopify unavailable')

      get "/enterprise/api/v1/accounts/#{shopify_account.id}/billing_summary",
          headers: shopify_admin.create_new_auth_token,
          params: { refresh: true },
          as: :json

      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body['error']).to eq('Shopify billing could not be verified right now')
    end

    it 'returns not found for a Shopify account when the feature gate is disabled' do
      allow(Shopify::FeatureGate).to receive(:enabled?).with(account: shopify_account).and_return(false)
      expect(Enterprise::Billing::ShopifySubscriptionSyncService).not_to receive(:new)

      get "/enterprise/api/v1/accounts/#{shopify_account.id}/billing_summary",
          headers: shopify_admin.create_new_auth_token,
          params: { refresh: true },
          as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'keeps the summary admin-only for Shopify accounts' do
      get "/enterprise/api/v1/accounts/#{shopify_account.id}/billing_summary",
          headers: shopify_agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /enterprise/api/v1/accounts/{account.id}/checkout' do
    before do
      create(
        :integrations_hook,
        :shopify,
        account: shopify_account,
        reference_id: 'billing-test-store.myshopify.com'
      )
    end

    it 'returns the trusted Shopify App Pricing URL with the existing redirect contract' do
      allow(GlobalConfigService).to receive(:load).with('SHOPIFY_APP_HANDLE', nil).and_return('chatwoot')
      expect(Enterprise::Billing::CreateSessionService).not_to receive(:new)

      post "/enterprise/api/v1/accounts/#{shopify_account.id}/checkout",
           headers: shopify_admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'redirect_url' => 'https://admin.shopify.com/store/billing-test-store/charges/chatwoot/pricing_plans'
      )
    end

    it 'does not fall through to Stripe when the Shopify feature gate is disabled' do
      allow(Shopify::FeatureGate).to receive(:enabled?).with(account: shopify_account).and_return(false)
      expect(Enterprise::Billing::CreateSessionService).not_to receive(:new)

      post "/enterprise/api/v1/accounts/#{shopify_account.id}/checkout",
           headers: shopify_admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns an actionable error when the Shopify app handle is not configured' do
      allow(GlobalConfigService).to receive(:load).with('SHOPIFY_APP_HANDLE', nil).and_return(nil)

      post "/enterprise/api/v1/accounts/#{shopify_account.id}/checkout",
           headers: shopify_admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to eq('Shopify App Pricing is not available right now')
    end

    it 'keeps checkout admin-only for Shopify accounts' do
      post "/enterprise/api/v1/accounts/#{shopify_account.id}/checkout",
           headers: shopify_agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'Stripe-only billing actions' do
    it 'rejects Shopify attempts to create a Stripe customer, choose currency, or buy credits' do
      expect(Enterprise::Billing::TopupCheckoutService).not_to receive(:new)

      post "/enterprise/api/v1/accounts/#{shopify_account.id}/subscription",
           headers: shopify_admin.create_new_auth_token,
           as: :json
      expect(response).to have_http_status(:unprocessable_entity)

      post "/enterprise/api/v1/accounts/#{shopify_account.id}/select_billing_currency",
           headers: shopify_admin.create_new_auth_token,
           params: { currency: 'usd' },
           as: :json
      expect(response).to have_http_status(:unprocessable_entity)

      post "/enterprise/api/v1/accounts/#{shopify_account.id}/topup_checkout",
           headers: shopify_admin.create_new_auth_token,
           params: { credits: 1000 },
           as: :json
      expect(response).to have_http_status(:unprocessable_entity)

      get "/enterprise/api/v1/accounts/#{shopify_account.id}/topup_options",
          headers: shopify_admin.create_new_auth_token,
          as: :json
      expect(response).to have_http_status(:unprocessable_entity)

      expect(response.parsed_body['error']).to eq('This billing action is not available for Shopify-billed accounts')
      expect(Enterprise::CreateStripeCustomerJob).not_to have_been_enqueued
    end
  end
end
