require 'rails_helper'

RSpec.describe Billable do
  let(:account) { create(:account) }

  # Helper to set up a fake_processor subscription for testing
  def create_fake_subscription(account, plan_key: 'pro_monthly', **)
    plan = PlanConfig.find(plan_key)
    account.set_payment_processor :fake_processor, allow_fake: true
    account.payment_processor.subscribe(
      plan: plan.stripe_price_id,
      **
    )
  end

  describe 'associations' do
    it 'has many usage_records' do
      expect(Account.reflect_on_association(:usage_records).macro).to eq(:has_many)
    end

    it 'has many pay_customers via pay gem' do
      expect(Account.reflect_on_association(:pay_customers).macro).to eq(:has_many)
    end
  end

  # ── Plan Resolution ────────────────────────────────────────────

  describe '#active_subscription' do
    it 'returns nil when no subscription exists' do
      expect(account.active_subscription).to be_nil
    end

    it 'returns the active Pay::Subscription' do
      create_fake_subscription(account)
      sub = account.active_subscription
      expect(sub).to be_a(Pay::Subscription)
      expect(sub).to be_active
    end
  end

  describe '#active_plan' do
    it 'returns nil when no subscription exists' do
      expect(account.active_plan).to be_nil
    end

    it 'returns PlanConfig for active subscription' do
      create_fake_subscription(account, plan_key: 'pro_monthly')
      plan = account.active_plan
      expect(plan).to be_a(PlanConfig)
      expect(plan.key).to eq('pro_monthly')
      expect(plan.tier).to eq('pro')
    end

    it 'returns PlanConfig for trial subscription' do
      trial_end = 14.days.from_now
      create_fake_subscription(account, plan_key: 'basic_monthly', trial_ends_at: trial_end, ends_at: trial_end)
      plan = account.active_plan
      expect(plan).to be_a(PlanConfig)
      expect(plan.key).to eq('basic_monthly')
    end

    it 'returns nil for ended subscription' do
      trial_end = 1.day.ago
      create_fake_subscription(account, plan_key: 'pro_monthly', trial_ends_at: trial_end, ends_at: trial_end)
      expect(account.active_plan).to be_nil
    end
  end

  describe '#plan_tier' do
    it 'returns nil when no plan' do
      expect(account.plan_tier).to be_nil
    end

    it 'returns the tier string' do
      create_fake_subscription(account, plan_key: 'basic_monthly')
      expect(account.plan_tier).to eq('basic')
    end
  end

  describe '#subscribed?' do
    it 'returns false when no subscription' do
      expect(account.subscribed?).to be false
    end

    it 'returns true with active subscription' do
      create_fake_subscription(account)
      expect(account.subscribed?).to be true
    end

    it 'returns true during trial' do
      trial_end = 14.days.from_now
      create_fake_subscription(account, trial_ends_at: trial_end, ends_at: trial_end)
      expect(account.subscribed?).to be true
    end

    it 'returns false after trial expires' do
      trial_end = 1.day.ago
      create_fake_subscription(account, trial_ends_at: trial_end, ends_at: trial_end)
      expect(account.subscribed?).to be false
    end
  end

  # ── Trial Logic ────────────────────────────────────────────────

  describe '#on_trial?' do
    it 'returns falsey with no subscription' do
      expect(account.on_trial?).to be_falsey
    end

    it 'returns true during active trial' do
      account.grant_trial!(days: 14)
      expect(account.on_trial?).to be true
    end

    it 'returns false when trial has expired' do
      account.grant_trial!(days: 14)
      sub = account.active_subscription
      sub.update!(trial_ends_at: 1.day.ago, ends_at: 1.day.ago)
      expect(account.on_trial?).to be false
    end
  end

  describe '#trial_active?' do
    it 'returns true when on trial with credits remaining' do
      account.grant_trial!(days: 14, credits: 500)
      expect(account.trial_active?).to be true
    end

    it 'returns false when trial credits exhausted' do
      account.grant_trial!(days: 14, credits: 500)
      account.update!(trial_credits_remaining: 0)
      expect(account.trial_active?).to be false
    end

    it 'returns false when trial time expired even with credits' do
      account.grant_trial!(days: 14, credits: 500)
      sub = account.active_subscription
      sub.update!(trial_ends_at: 1.day.ago, ends_at: 1.day.ago)
      expect(account.trial_active?).to be false
    end
  end

  describe '#ai_responses_allowed?' do
    it 'returns false with no subscription' do
      expect(account.ai_responses_allowed?).to be false
    end

    it 'returns true with active paid subscription' do
      create_fake_subscription(account)
      expect(account.ai_responses_allowed?).to be true
    end

    it 'returns true on trial with credits' do
      account.grant_trial!(days: 14, credits: 500)
      expect(account.ai_responses_allowed?).to be true
    end

    it 'returns false on trial with zero credits' do
      account.grant_trial!(days: 14, credits: 500)
      account.update!(trial_credits_remaining: 0)
      expect(account.ai_responses_allowed?).to be false
    end
  end

  # ── Usage Tracking ─────────────────────────────────────────────

  describe '#current_usage' do
    it 'returns an AccountUsageRecord for the current month' do
      usage = account.current_usage
      expect(usage).to be_a(AccountUsageRecord)
      expect(usage.period_date).to eq(Time.current.beginning_of_month.to_date)
    end
  end

  describe '#within_ai_limit?' do
    it 'returns true when no plan (legacy accounts)' do
      expect(account.within_ai_limit?).to be true
    end

    context 'with active subscription' do
      before { create_fake_subscription(account, plan_key: 'basic_monthly') }

      it 'returns true when under limit' do
        expect(account.within_ai_limit?).to be true
      end

      it 'returns false when at or over limit' do
        account.current_usage.update!(ai_responses_count: 10_000)
        expect(account.within_ai_limit?).to be false
      end

      it 'accounts for bonus credits' do
        account.current_usage.update!(ai_responses_count: 10_000, bonus_credits: 500)
        expect(account.within_ai_limit?).to be true
      end
    end
  end

  describe '#within_limit?' do
    before { create_fake_subscription(account, plan_key: 'basic_monthly') }

    it 'returns true when current_count is below limit' do
      expect(account.within_limit?(:knowledge_base_documents, 50)).to be true
    end

    it 'returns false when current_count meets or exceeds limit' do
      expect(account.within_limit?(:knowledge_base_documents, 100)).to be false
    end

    it 'returns true for undefined limit resources' do
      expect(account.within_limit?(:nonexistent_resource, 999)).to be true
    end

    it 'returns true when no plan' do
      other_account = create(:account)
      expect(other_account.within_limit?(:knowledge_base_documents, 999)).to be true
    end
  end

  describe '#track_ai_response!' do
    it 'increments the AI response counter' do
      expect { account.track_ai_response! }.to change { account.current_usage.reload.ai_responses_count }.by(1)
    end

    it 'accepts a custom count' do
      expect { account.track_ai_response!(5) }.to change { account.current_usage.reload.ai_responses_count }.by(5)
    end

    context 'on trial' do
      before { account.grant_trial!(days: 14, credits: 500) }

      it 'decrements trial_credits_remaining' do
        expect { account.track_ai_response! }.to change { account.reload.trial_credits_remaining }.by(-1)
      end

      it 'decrements by custom count' do
        expect { account.track_ai_response!(5) }.to change { account.reload.trial_credits_remaining }.by(-5)
      end

      it 'does not go below zero' do
        account.update!(trial_credits_remaining: 2)
        account.track_ai_response!(5)
        expect(account.reload.trial_credits_remaining).to eq(0)
      end
    end

    context 'on paid plan with overage' do
      before { create_fake_subscription(account, plan_key: 'basic_monthly') }

      it 'tracks overage when usage exceeds plan limit' do
        account.current_usage.update!(ai_responses_count: 10_000)
        account.track_ai_response!
        expect(account.current_usage.reload.overage_count).to eq(1)
      end

      it 'calculates overage considering bonus credits' do
        account.current_usage.update!(ai_responses_count: 10_500, bonus_credits: 1000)
        account.track_ai_response!
        # 10501 usage, effective limit = 10000 + 1000 = 11000 → no overage
        expect(account.current_usage.reload.overage_count).to eq(0)
      end

      it 'does not track overage when within limit' do
        account.current_usage.update!(ai_responses_count: 5000)
        account.track_ai_response!
        expect(account.current_usage.reload.overage_count).to eq(0)
      end
    end
  end

  describe '#clear_trial_credits!' do
    it 'sets trial_credits_remaining to 0' do
      account.update!(trial_credits_remaining: 500)
      account.clear_trial_credits!
      expect(account.reload.trial_credits_remaining).to eq(0)
    end

    it 'does nothing when already 0' do
      account.update!(trial_credits_remaining: 0)
      expect { account.clear_trial_credits! }.not_to(change { account.reload.updated_at })
    end
  end

  describe '#track_voice_note!' do
    it 'increments voice notes and AI responses (1 note = 6 responses)' do
      account.track_voice_note!
      usage = account.current_usage.reload
      expect(usage.voice_notes_count).to eq(1)
      expect(usage.ai_responses_count).to eq(6)
    end
  end

  describe '#usage_summary' do
    it 'returns a summary hash' do
      create_fake_subscription(account, plan_key: 'pro_monthly')
      account.track_ai_response!(100)

      summary = account.usage_summary
      expect(summary[:ai_responses_count]).to eq(100)
      expect(summary[:ai_responses_limit]).to eq(25_000)
      expect(summary[:voice_notes_count]).to eq(0)
      expect(summary[:usage_percentage]).to be_a(Float)
    end

    it 'returns nil limit and percentage when no plan' do
      summary = account.usage_summary
      expect(summary[:ai_responses_limit]).to be_nil
      expect(summary[:usage_percentage]).to be_nil
    end
  end

  # ── Subscription Lifecycle ─────────────────────────────────────

  describe '#checkout_url' do
    it 'creates a Stripe checkout session and returns URL' do
      checkout_session = double('Stripe::Checkout::Session', url: 'https://checkout.stripe.com/test')
      account.set_payment_processor :stripe
      allow(account.payment_processor).to receive(:checkout).and_return(checkout_session)

      url = account.checkout_url('pro_monthly', success_url: 'https://app.test/success', cancel_url: 'https://app.test/cancel')
      expect(url).to eq('https://checkout.stripe.com/test')
    end
  end

  describe '#billing_portal_url' do
    it 'creates a Stripe billing portal session and returns URL' do
      portal_session = double('Stripe::BillingPortal::Session', url: 'https://billing.stripe.com/test')
      account.set_payment_processor :stripe
      allow(account.payment_processor).to receive(:billing_portal).and_return(portal_session)

      url = account.billing_portal_url(return_url: 'https://app.test/billing')
      expect(url).to eq('https://billing.stripe.com/test')
    end
  end

  describe '#swap_plan!' do
    it 'swaps the subscription to a new plan' do
      create_fake_subscription(account, plan_key: 'basic_monthly')
      account.swap_plan!('pro_monthly')

      pro_plan = PlanConfig.find('pro_monthly')
      expect(account.active_subscription.processor_plan).to eq(pro_plan.stripe_price_id)
    end

    it 'syncs features after swap' do
      create_fake_subscription(account, plan_key: 'basic_monthly')
      account.swap_plan!('pro_monthly')
      expect(account.active_plan.tier).to eq('pro')
    end

    it 'raises error when no subscription' do
      expect { account.swap_plan!('pro_monthly') }.to raise_error(RuntimeError, /No active subscription/)
    end
  end

  describe '#cancel_subscription!' do
    it 'cancels the subscription at period end' do
      create_fake_subscription(account)
      account.cancel_subscription!
      expect(account.active_subscription.ends_at).to be_present
    end

    it 'raises error when no subscription' do
      expect { account.cancel_subscription! }.to raise_error(RuntimeError, /No active subscription/)
    end
  end

  describe '#resume_subscription!' do
    it 'resumes a cancelled subscription' do
      create_fake_subscription(account)
      account.cancel_subscription!
      account.resume_subscription!
      expect(account.active_subscription.reload.ends_at).to be_nil
    end

    it 'raises error when no subscription' do
      expect { account.resume_subscription! }.to raise_error(RuntimeError, /No active subscription/)
    end
  end

  # ── Plan ↔ Feature Sync ────────────────────────────────────────

  describe '#sync_plan_features!' do
    it 'syncs limits from active plan to account' do
      create_fake_subscription(account, plan_key: 'pro_monthly')
      account.sync_plan_features!
      account.reload

      expect(account.limits['ai_responses_per_month']).to eq(25_000)
      expect(account.limits['knowledge_base_documents']).to eq(200)
    end

    it 'clears limits when no plan' do
      account.update!(limits: { 'ai_responses_per_month' => 10_000 })
      account.sync_plan_features!
      account.reload

      expect(account.limits['ai_responses_per_month']).to be_nil
    end

    it 'enables CRM feature flag for pro plan' do
      create_fake_subscription(account, plan_key: 'pro_monthly')
      account.sync_plan_features!
      expect(account.feature_enabled?(:crm)).to be true
    end

    it 'disables CRM feature flag for basic plan' do
      create_fake_subscription(account, plan_key: 'basic_monthly')
      account.sync_plan_features!
      expect(account.feature_enabled?(:crm)).to be false
    end

    it 'disables CRM when plan is removed' do
      create_fake_subscription(account, plan_key: 'pro_monthly')
      account.sync_plan_features!
      expect(account.feature_enabled?(:crm)).to be true

      # End the subscription
      account.active_subscription.update!(status: 'canceled', ends_at: 1.day.ago)
      account.sync_plan_features!
      expect(account.feature_enabled?(:crm)).to be false
    end
  end

  describe '#plan_feature_available?' do
    it 'returns true when no plan (legacy accounts)' do
      expect(account.plan_feature_available?(:crm_integration)).to be true
    end

    it 'returns false for basic plan premium features' do
      create_fake_subscription(account, plan_key: 'basic_monthly')
      expect(account.plan_feature_available?(:crm_integration)).to be false
    end

    it 'returns true for pro plan features' do
      create_fake_subscription(account, plan_key: 'pro_monthly')
      expect(account.plan_feature_available?(:crm_integration)).to be true
    end
  end

  # ── Admin Toolkit ──────────────────────────────────────────────

  describe '#grant_trial!' do
    it 'creates a trial subscription with fake_processor' do
      account.grant_trial!(days: 14)
      sub = account.active_subscription

      expect(sub).to be_present
      expect(sub.customer.processor).to eq('fake_processor')
      expect(sub.trial_ends_at).to be_within(1.minute).of(14.days.from_now)
    end

    it 'uses specified plan' do
      account.grant_trial!(days: 30, plan_key: 'basic_monthly')
      plan = account.active_plan
      expect(plan.key).to eq('basic_monthly')
    end

    it 'syncs features after granting trial' do
      account.grant_trial!(days: 14, plan_key: 'pro_monthly')
      account.reload
      expect(account.limits['ai_responses_per_month']).to eq(25_000)
    end
  end

  describe '#extend_trial!' do
    it 'extends a fake_processor trial by N days' do
      account.grant_trial!(days: 14)
      original_end = account.active_subscription.ends_at

      account.extend_trial!(days: 7)
      expect(account.active_subscription.reload.ends_at).to be_within(1.minute).of(original_end + 7.days)
    end

    it 'raises error when no subscription' do
      expect { account.extend_trial!(days: 7) }.to raise_error(RuntimeError, /No active subscription/)
    end
  end

  describe '#grant_complimentary!' do
    it 'creates a complimentary subscription with fake_processor' do
      account.grant_complimentary!(plan_key: 'pro_annual')

      sub = account.active_subscription
      expect(sub).to be_present
      expect(sub.customer.processor).to eq('fake_processor')
      expect(sub).to be_active
      expect(account.active_plan.key).to eq('pro_annual')
    end

    it 'syncs features' do
      account.grant_complimentary!(plan_key: 'pro_monthly')
      account.reload
      expect(account.limits['ai_responses_per_month']).to eq(25_000)
    end
  end

  describe '#apply_coupon!' do
    it 'raises error when no subscription' do
      expect { account.apply_coupon!('TEST') }.to raise_error(RuntimeError, /No active subscription/)
    end

    it 'raises error for non-Stripe subscriptions' do
      account.grant_complimentary!
      expect { account.apply_coupon!('TEST') }.to raise_error(RuntimeError, /Coupons only work with Stripe/)
    end
  end

  describe '#override_plan!' do
    it 'creates a complimentary subscription for the given plan' do
      account.override_plan!('pro_annual')
      expect(account.active_plan.key).to eq('pro_annual')
      expect(account.active_subscription.customer.processor).to eq('fake_processor')
    end

    it 'replaces an existing subscription' do
      account.grant_complimentary!(plan_key: 'basic_monthly')
      account.override_plan!('pro_annual')
      expect(account.active_plan.key).to eq('pro_annual')
    end

    it 'syncs features after override' do
      account.override_plan!('pro_monthly')
      account.reload
      expect(account.limits['ai_responses_per_month']).to eq(25_000)
    end
  end

  describe '#add_bonus_credits!' do
    it 'adds bonus credits to current usage record' do
      expect { account.add_bonus_credits!(5000) }.to change { account.current_usage.reload.bonus_credits }.by(5000)
    end

    it 'accumulates credits on repeated calls' do
      account.add_bonus_credits!(1000)
      account.add_bonus_credits!(2000)
      expect(account.current_usage.reload.bonus_credits).to eq(3000)
    end
  end

  describe '#reset_usage!' do
    it 'resets AI and voice note counts to zero' do
      account.track_ai_response!(500)
      account.track_voice_note!(10)
      account.reset_usage!

      usage = account.current_usage.reload
      expect(usage.ai_responses_count).to eq(0)
      expect(usage.voice_notes_count).to eq(0)
    end
  end

  describe '#suspend_for_nonpayment!' do
    it 'suspends the account' do
      account.suspend_for_nonpayment!
      expect(account.reload.status).to eq('suspended')
    end

    it 'records suspension reason in custom_attributes' do
      account.suspend_for_nonpayment!
      expect(account.reload.custom_attributes['suspension_reason']).to eq('nonpayment')
      expect(account.custom_attributes['suspended_at']).to be_present
    end
  end

  describe '#reactivate_after_payment!' do
    it 'reactivates a suspended account' do
      account.suspend_for_nonpayment!
      account.reactivate_after_payment!

      expect(account.reload.status).to eq('active')
      expect(account.custom_attributes['suspension_reason']).to be_nil
    end

    it 'does nothing if account is not suspended for nonpayment' do
      account.reactivate_after_payment!
      expect(account.reload.status).to eq('active')
    end

    it 'does nothing if suspended for other reasons' do
      account.update!(status: :suspended, custom_attributes: { 'suspension_reason' => 'abuse' })
      account.reactivate_after_payment!
      expect(account.reload.status).to eq('suspended')
    end
  end

  describe '#billing_status' do
    it 'returns a complete billing status hash' do
      create_fake_subscription(account, plan_key: 'pro_monthly')
      account.track_ai_response!(42)

      status = account.billing_status
      expect(status[:plan_name]).to eq('Pro')
      expect(status[:plan_tier]).to eq('pro')
      expect(status[:subscription_status]).to eq('active')
      expect(status[:is_complimentary]).to be true
      expect(status[:usage][:ai_responses_count]).to eq(42)
    end

    it 'handles accounts with no subscription' do
      status = account.billing_status
      expect(status[:plan_name]).to be_nil
      expect(status[:subscription_status]).to be_nil
    end
  end

  # ── Email Resolution ─────────────────────────────────────────────

  describe '#email' do
    it 'returns support_email by default (for pay gem)' do
      account.update!(support_email: 'billing@example.com')
      expect(account.email).to eq('billing@example.com')
    end

    it 'falls back to env/global config when support_email column is blank' do
      # support_email method always falls back to MAILER_SENDER_EMAIL or GlobalConfig
      # so it never returns nil — just verify it returns a valid email string
      expect(account.email).to be_a(String)
      expect(account.email).to include('@')
    end
  end
end
