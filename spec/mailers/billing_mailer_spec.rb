require 'rails_helper'

RSpec.describe BillingMailer do
  let(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let(:class_instance) { described_class.new }

  before do
    allow(described_class).to receive(:new).and_return(class_instance)
    allow(class_instance).to receive(:smtp_config_set_or_development?).and_return(true)
  end

  # Helper to create a subscription for testing
  def grant_subscription(account, plan_key: 'pro_monthly')
    plan = PlanConfig.find(plan_key)
    account.set_payment_processor :fake_processor, allow_fake: true
    account.payment_processor.subscribe(plan: plan.stripe_price_id)
    account.sync_plan_features!
  end

  describe '#trial_expiring' do
    it 'sends email with trial expiration details' do
      mail = described_class.with(account: account).trial_expiring(account, days_remaining: 3).deliver_now

      expect(mail).to be_present
      expect(mail.to).to include(admin.email)
      expect(mail.subject).to include('trial')
    end
  end

  describe '#trial_expired' do
    it 'sends email about expired trial' do
      mail = described_class.with(account: account).trial_expired(account).deliver_now

      expect(mail).to be_present
      expect(mail.to).to include(admin.email)
      expect(mail.subject).to include('trial')
    end
  end

  describe '#payment_failed' do
    it 'sends email about payment failure' do
      mail = described_class.with(account: account).payment_failed(account).deliver_now

      expect(mail).to be_present
      expect(mail.to).to include(admin.email)
      expect(mail.subject).to include('payment')
    end
  end

  describe '#usage_warning' do
    it 'sends email about high usage' do
      mail = described_class.with(account: account).usage_warning(account, percentage: 85).deliver_now

      expect(mail).to be_present
      expect(mail.to).to include(admin.email)
      expect(mail.subject).to include('85%')
    end
  end

  describe '#usage_limit_reached' do
    it 'sends email about reaching usage limit' do
      mail = described_class.with(account: account).usage_limit_reached(account).deliver_now

      expect(mail).to be_present
      expect(mail.to).to include(admin.email)
      expect(mail.subject).to include('limit')
    end
  end

  describe '#welcome_to_plan' do
    it 'sends welcome email with plan details' do
      grant_subscription(account, plan_key: 'pro_monthly')

      mail = described_class.with(account: account).welcome_to_plan(account).deliver_now

      expect(mail).to be_present
      expect(mail.to).to include(admin.email)
      expect(mail.subject).to include('Welcome')
    end
  end

  describe '#plan_changed' do
    it 'sends email about plan change' do
      mail = described_class.with(account: account).plan_changed(account, old_plan_name: 'Basic Monthly').deliver_now

      expect(mail).to be_present
      expect(mail.to).to include(admin.email)
      expect(mail.subject).to include('plan')
    end
  end

  describe '#account_suspended' do
    it 'sends email about account suspension' do
      mail = described_class.with(account: account).account_suspended(account).deliver_now

      expect(mail).to be_present
      expect(mail.to).to include(admin.email)
      expect(mail.subject).to include('suspended')
    end
  end

  describe '#account_reactivated' do
    it 'sends email about account reactivation' do
      mail = described_class.with(account: account).account_reactivated(account).deliver_now

      expect(mail).to be_present
      expect(mail.to).to include(admin.email)
      expect(mail.subject).to include('reactivated')
    end
  end

  describe 'when SMTP is not configured' do
    before do
      allow(class_instance).to receive(:smtp_config_set_or_development?).and_return(false)
    end

    it 'does not send email' do
      mail = described_class.with(account: account).trial_expiring(account, days_remaining: 3).deliver_now
      expect(mail).to be_nil
    end
  end
end
