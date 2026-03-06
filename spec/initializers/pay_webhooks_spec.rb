require 'rails_helper'

# Tests the custom webhook handler logic defined in config/initializers/pay_webhooks.rb.
# We test the handler methods on BillingWebhookHandlers directly rather than
# instrumenting through Pay's delegator (which also triggers Pay's built-in
# Stripe API sync handlers).
RSpec.describe BillingWebhookHandlers do
  let(:account) { create(:account) }

  # Helper to create Pay records for testing
  def setup_pay_subscription(account, plan_key: 'pro_monthly', status: 'active')
    plan = PlanConfig.find(plan_key)
    account.set_payment_processor :fake_processor, allow_fake: true
    pay_customer = account.payment_processor
    sub = pay_customer.subscribe(plan: plan.stripe_price_id)
    sub.update!(status: status) if status != 'active'
    [pay_customer, sub]
  end

  describe '.handle_plan_sync' do
    it 'syncs plan features when subscription is active' do
      _, pay_sub = setup_pay_subscription(account, plan_key: 'pro_monthly')

      described_class.handle_plan_sync(pay_sub)

      account.reload
      expect(account.limits['ai_responses_per_month']).to eq(25_000)
      expect(account.limits['knowledge_base_documents']).to eq(200)
    end

    it 'clears plan features when subscription is ended' do
      _, pay_sub = setup_pay_subscription(account, plan_key: 'pro_monthly')
      account.sync_plan_features!
      expect(account.reload.limits['ai_responses_per_month']).to eq(25_000)

      # Simulate subscription ending
      pay_sub.update!(status: 'canceled', ends_at: 1.day.ago)

      described_class.handle_plan_sync(pay_sub)

      account.reload
      expect(account.limits['ai_responses_per_month']).to be_nil
    end

    it 'ignores nil subscription' do
      expect { described_class.handle_plan_sync(nil) }.not_to raise_error
    end
  end

  describe '.handle_subscription_updated' do
    it 'suspends account when subscription status is unpaid' do
      _pay_customer, pay_sub = setup_pay_subscription(account)
      pay_sub.update!(status: 'unpaid')

      described_class.handle_subscription_updated(pay_sub)

      expect(account.reload.status).to eq('suspended')
      expect(account.custom_attributes['suspension_reason']).to eq('nonpayment')
    end

    it 'does not suspend for active status' do
      _pay_customer, pay_sub = setup_pay_subscription(account)

      described_class.handle_subscription_updated(pay_sub)

      expect(account.reload.status).to eq('active')
    end

    it 'also syncs plan features' do
      _pay_customer, pay_sub = setup_pay_subscription(account, plan_key: 'pro_monthly')

      described_class.handle_subscription_updated(pay_sub)

      account.reload
      expect(account.limits['ai_responses_per_month']).to eq(25_000)
    end
  end

  describe '.handle_charge_succeeded' do
    it 'reactivates a suspended account' do
      pay_customer, _pay_sub = setup_pay_subscription(account)
      account.suspend_for_nonpayment!

      described_class.handle_charge_succeeded(pay_customer)

      expect(account.reload.status).to eq('active')
      expect(account.custom_attributes['suspension_reason']).to be_nil
    end

    it 'does nothing for active accounts' do
      pay_customer, _pay_sub = setup_pay_subscription(account)

      described_class.handle_charge_succeeded(pay_customer)

      expect(account.reload.status).to eq('active')
    end
  end

  describe '.handle_checkout_completed' do
    it 'syncs plan features after checkout' do
      pay_customer, _pay_sub = setup_pay_subscription(account, plan_key: 'pro_monthly')

      described_class.handle_checkout_completed(pay_customer)

      account.reload
      expect(account.limits['ai_responses_per_month']).to eq(25_000)
    end
  end
end
