require 'rails_helper'

RSpec.describe 'Subscriptions API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  # Helper to grant a subscription via fake_processor
  def grant_subscription(account, plan_key: 'pro_monthly')
    plan = PlanConfig.find(plan_key)
    account.set_payment_processor :fake_processor, allow_fake: true
    account.payment_processor.subscribe(plan: plan.stripe_price_id)
  end

  describe 'GET /api/v1/accounts/:account_id/subscription' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/subscription"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as agent' do
      it 'returns unauthorized (admin only)' do
        get "/api/v1/accounts/#{account.id}/subscription",
            headers: agent.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as admin' do
      it 'returns subscription data with no active subscription' do
        get "/api/v1/accounts/#{account.id}/subscription",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json['subscription']).to be_nil
        expect(json['plan']).to be_nil
        expect(json['plans']).to be_an(Array)
        expect(json['plans'].length).to eq(4)
      end

      it 'returns subscription data with active subscription' do
        grant_subscription(account, plan_key: 'pro_monthly')

        get "/api/v1/accounts/#{account.id}/subscription",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json['subscription']['status']).to eq('active')
        expect(json['plan']['key']).to eq('pro_monthly')
        expect(json['plan']['tier']).to eq('pro')
        expect(json['usage']['ai_responses_count']).to eq(0)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/subscription/checkout' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/subscription/checkout"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as admin' do
      it 'returns a checkout URL' do
        checkout_session = double('CheckoutSession', url: 'https://checkout.stripe.com/test_session')
        account.set_payment_processor :stripe
        allow_any_instance_of(Pay::Stripe::Customer).to receive(:checkout).and_return(checkout_session)

        post "/api/v1/accounts/#{account.id}/subscription/checkout",
             params: { plan_key: 'pro_monthly' },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json['checkout_url']).to eq('https://checkout.stripe.com/test_session')
      end

      it 'returns error for invalid plan key' do
        post "/api/v1/accounts/#{account.id}/subscription/checkout",
             params: { plan_key: 'nonexistent' },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/subscription/portal' do
    context 'when authenticated as admin' do
      it 'returns a billing portal URL' do
        portal_session = double('PortalSession', url: 'https://billing.stripe.com/test_portal')
        account.set_payment_processor :stripe
        allow_any_instance_of(Pay::Stripe::Customer).to receive(:billing_portal).and_return(portal_session)

        post "/api/v1/accounts/#{account.id}/subscription/portal",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json['portal_url']).to eq('https://billing.stripe.com/test_portal')
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/subscription/swap' do
    context 'when authenticated as admin' do
      it 'swaps the subscription plan' do
        grant_subscription(account, plan_key: 'basic_monthly')

        post "/api/v1/accounts/#{account.id}/subscription/swap",
             params: { plan_key: 'pro_monthly' },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(account.reload.active_plan.key).to eq('pro_monthly')
      end

      it 'returns error when no subscription' do
        post "/api/v1/accounts/#{account.id}/subscription/swap",
             params: { plan_key: 'pro_monthly' },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/subscription/cancel' do
    context 'when authenticated as admin' do
      it 'cancels the subscription' do
        grant_subscription(account)

        post "/api/v1/accounts/#{account.id}/subscription/cancel",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(account.active_subscription.ends_at).to be_present
      end

      it 'returns error when no subscription' do
        post "/api/v1/accounts/#{account.id}/subscription/cancel",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST /api/v1/accounts/:account_id/subscription/resume' do
    context 'when authenticated as admin' do
      it 'resumes a cancelled subscription' do
        grant_subscription(account)
        account.cancel_subscription!

        post "/api/v1/accounts/#{account.id}/subscription/resume",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(account.active_subscription.reload.ends_at).to be_nil
      end

      it 'returns error when no subscription' do
        post "/api/v1/accounts/#{account.id}/subscription/resume",
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
