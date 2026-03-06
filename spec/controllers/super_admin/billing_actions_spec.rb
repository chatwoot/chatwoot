require 'rails_helper'

# Tests the super admin billing actions added to SuperAdmin::AccountsController.
# Each action delegates to a Billable method on the account, so we verify:
#   1. Unauthenticated requests redirect (Devise guard)
#   2. Authenticated requests execute the action and redirect with a flash notice
#   3. Error cases return an appropriate flash alert
RSpec.describe 'Super Admin billing actions', type: :request do
  let!(:super_admin) { create(:super_admin) }
  let!(:account) { create(:account) }

  # Helper to create a fake subscription for the account
  def grant_subscription(account, plan_key: 'pro_monthly', status: 'active')
    plan = PlanConfig.find(plan_key)
    account.set_payment_processor :fake_processor, allow_fake: true
    sub = account.payment_processor.subscribe(plan: plan.stripe_price_id)
    sub.update!(status: status) if status != 'active'
    sub
  end

  shared_examples 'requires super admin auth' do |method, path_lambda|
    it 'redirects unauthenticated requests' do
      send(method, instance_exec(&path_lambda))
      expect(response).to have_http_status(:redirect)
    end
  end

  # ── Grant Trial ────────────────────────────────────────────────

  describe 'POST /super_admin/accounts/:id/grant_trial' do
    let(:path) { "/super_admin/accounts/#{account.id}/grant_trial" }

    it_behaves_like 'requires super admin auth', :post, -> { "/super_admin/accounts/#{account.id}/grant_trial" }

    context 'when authenticated' do
      before { sign_in(super_admin, scope: :super_admin) }

      it 'grants a trial and redirects with notice' do
        post path, params: { days: 14, plan_key: 'pro_monthly' }

        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to include('Trial')

        account.reload
        expect(account.subscribed?).to be true
        sub = account.active_subscription
        expect(sub.on_trial?).to be true
      end

      it 'defaults to 14 days and pro_monthly when params omitted' do
        post path

        account.reload
        expect(account.subscribed?).to be true
        expect(account.active_plan.key).to eq('pro_monthly')
      end
    end
  end

  # ── Extend Trial ───────────────────────────────────────────────

  describe 'POST /super_admin/accounts/:id/extend_trial' do
    let(:path) { "/super_admin/accounts/#{account.id}/extend_trial" }

    it_behaves_like 'requires super admin auth', :post, -> { "/super_admin/accounts/#{account.id}/extend_trial" }

    context 'when authenticated' do
      before { sign_in(super_admin, scope: :super_admin) }

      it 'extends an existing trial' do
        account.grant_trial!(days: 7, plan_key: 'pro_monthly')
        original_end = account.active_subscription.ends_at

        post path, params: { days: 14 }

        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to include('Trial')

        account.reload
        expect(account.active_subscription.ends_at).to be > original_end
      end

      it 'shows error when no subscription exists' do
        post path, params: { days: 14 }

        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end
  end

  # ── Grant Complimentary ────────────────────────────────────────

  describe 'POST /super_admin/accounts/:id/grant_complimentary' do
    let(:path) { "/super_admin/accounts/#{account.id}/grant_complimentary" }

    it_behaves_like 'requires super admin auth', :post, -> { "/super_admin/accounts/#{account.id}/grant_complimentary" }

    context 'when authenticated' do
      before { sign_in(super_admin, scope: :super_admin) }

      it 'grants a complimentary subscription' do
        post path, params: { plan_key: 'pro_monthly' }

        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to include('Complimentary')

        account.reload
        expect(account.subscribed?).to be true
        expect(account.active_subscription.customer.processor).to eq('fake_processor')
      end

      it 'defaults to pro_monthly' do
        post path

        account.reload
        expect(account.active_plan.key).to eq('pro_monthly')
      end
    end
  end

  # ── Override Plan ──────────────────────────────────────────────

  describe 'POST /super_admin/accounts/:id/override_plan' do
    let(:path) { "/super_admin/accounts/#{account.id}/override_plan" }

    it_behaves_like 'requires super admin auth', :post, -> { "/super_admin/accounts/#{account.id}/override_plan" }

    context 'when authenticated' do
      before { sign_in(super_admin, scope: :super_admin) }

      it 'overrides the plan' do
        post path, params: { plan_key: 'basic_monthly' }

        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to include('Plan')

        account.reload
        expect(account.active_plan.key).to eq('basic_monthly')
      end

      it 'shows error for invalid plan' do
        post path, params: { plan_key: 'nonexistent' }

        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end
  end

  # ── Add Bonus Credits ──────────────────────────────────────────

  describe 'POST /super_admin/accounts/:id/add_bonus_credits' do
    let(:path) { "/super_admin/accounts/#{account.id}/add_bonus_credits" }

    it_behaves_like 'requires super admin auth', :post, -> { "/super_admin/accounts/#{account.id}/add_bonus_credits" }

    context 'when authenticated' do
      before { sign_in(super_admin, scope: :super_admin) }

      it 'adds bonus credits' do
        post path, params: { amount: 5000 }

        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to include('bonus')

        expect(account.current_usage.bonus_credits).to eq(5000)
      end

      it 'defaults to 1000 credits when no amount given' do
        post path

        expect(account.current_usage.bonus_credits).to eq(1000)
      end
    end
  end

  # ── Reset Usage ────────────────────────────────────────────────

  describe 'POST /super_admin/accounts/:id/reset_usage' do
    let(:path) { "/super_admin/accounts/#{account.id}/reset_usage" }

    it_behaves_like 'requires super admin auth', :post, -> { "/super_admin/accounts/#{account.id}/reset_usage" }

    context 'when authenticated' do
      before { sign_in(super_admin, scope: :super_admin) }

      it 'resets usage counters' do
        account.track_ai_response!(100)
        expect(account.current_usage.ai_responses_count).to eq(100)

        post path

        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to include('Usage')

        expect(account.current_usage.reload.ai_responses_count).to eq(0)
      end
    end
  end

  # ── Cancel Subscription ────────────────────────────────────────

  describe 'POST /super_admin/accounts/:id/cancel_subscription' do
    let(:path) { "/super_admin/accounts/#{account.id}/cancel_subscription" }

    it_behaves_like 'requires super admin auth', :post, -> { "/super_admin/accounts/#{account.id}/cancel_subscription" }

    context 'when authenticated' do
      before { sign_in(super_admin, scope: :super_admin) }

      it 'cancels the subscription' do
        grant_subscription(account)

        post path

        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to include('cancel')
      end

      it 'shows error when no subscription exists' do
        post path

        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to be_present
      end
    end
  end

  # ── Suspend Account ────────────────────────────────────────────

  describe 'POST /super_admin/accounts/:id/suspend' do
    let(:path) { "/super_admin/accounts/#{account.id}/suspend" }

    it_behaves_like 'requires super admin auth', :post, -> { "/super_admin/accounts/#{account.id}/suspend" }

    context 'when authenticated' do
      before { sign_in(super_admin, scope: :super_admin) }

      it 'suspends the account' do
        post path

        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to include('suspended')

        expect(account.reload.status).to eq('suspended')
        expect(account.custom_attributes['suspension_reason']).to eq('nonpayment')
      end
    end
  end

  # ── Reactivate Account ─────────────────────────────────────────

  describe 'POST /super_admin/accounts/:id/reactivate' do
    let(:path) { "/super_admin/accounts/#{account.id}/reactivate" }

    it_behaves_like 'requires super admin auth', :post, -> { "/super_admin/accounts/#{account.id}/reactivate" }

    context 'when authenticated' do
      before { sign_in(super_admin, scope: :super_admin) }

      it 'reactivates a suspended account' do
        grant_subscription(account)
        account.suspend_for_nonpayment!
        expect(account.reload.status).to eq('suspended')

        post path

        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to include('reactivated')

        expect(account.reload.status).to eq('active')
      end

      it 'shows notice even when account is already active' do
        post path

        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to be_present
      end
    end
  end

  # ── Billing Status Display ─────────────────────────────────────

  describe 'GET /super_admin/accounts/:id (billing info)' do
    context 'when authenticated' do
      before { sign_in(super_admin, scope: :super_admin) }

      it 'shows the account page with billing section' do
        grant_subscription(account, plan_key: 'pro_monthly')

        get "/super_admin/accounts/#{account.id}"

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Billing')
      end
    end
  end
end
