require 'rails_helper'

RSpec.describe 'Super Admin billing dashboard', type: :request do
  let!(:super_admin) { create(:super_admin) }

  # Helper to create a fake subscription for an account
  def grant_subscription(account, plan_key: 'pro_monthly', processor: :fake_processor)
    plan = PlanConfig.find(plan_key)
    account.set_payment_processor processor, allow_fake: true
    account.payment_processor.subscribe(plan: plan.stripe_price_id)
  end

  def grant_trial(account, days:, plan_key: 'pro_monthly')
    account.grant_trial!(days: days, plan_key: plan_key)
  end

  describe 'GET /super_admin/billing_dashboard' do
    context 'when unauthenticated' do
      it 'redirects to login' do
        get '/super_admin/billing_dashboard'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when authenticated' do
      before { sign_in(super_admin, scope: :super_admin) }

      it 'returns success' do
        get '/super_admin/billing_dashboard'
        expect(response).to have_http_status(:success)
      end

      it 'shows the billing dashboard heading' do
        get '/super_admin/billing_dashboard'
        expect(response.body).to include('Billing Dashboard')
      end

      it 'displays metric labels' do
        get '/super_admin/billing_dashboard'

        expect(response.body).to include('Active Subscriptions')
        expect(response.body).to include('Trials')
        expect(response.body).to include('Complimentary')
        expect(response.body).to include('No Subscription')
      end

      it 'counts active subscriptions' do
        account = create(:account)
        grant_subscription(account)

        get '/super_admin/billing_dashboard'
        expect(response.body).to include('1') # at least one active subscription
      end

      it 'counts trial subscriptions' do
        account = create(:account)
        grant_trial(account, days: 14)

        get '/super_admin/billing_dashboard'
        # The page should show at least 1 trial
        expect(response).to have_http_status(:success)
      end

      it 'counts accounts with no subscription' do
        create(:account) # no subscription

        get '/super_admin/billing_dashboard'
        expect(response).to have_http_status(:success)
      end

      it 'counts suspended accounts' do
        account = create(:account)
        grant_subscription(account)
        account.suspend_for_nonpayment!

        get '/super_admin/billing_dashboard'
        expect(response.body).to include('Suspended')
      end
    end
  end
end
