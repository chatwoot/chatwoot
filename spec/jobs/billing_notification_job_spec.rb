require 'rails_helper'

RSpec.describe BillingNotificationJob, type: :job do
  let(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }

  # Helper to create a fake trial subscription
  def grant_trial(account, days:, plan_key: 'pro_monthly')
    account.grant_trial!(days: days, plan_key: plan_key)
  end

  # Helper to create a fake active subscription
  def grant_subscription(account, plan_key: 'pro_monthly')
    plan = PlanConfig.find(plan_key)
    account.set_payment_processor :fake_processor, allow_fake: true
    account.payment_processor.subscribe(plan: plan.stripe_price_id)
    account.sync_plan_features!
  end

  describe 'queue configuration' do
    it 'enqueues on scheduled_jobs queue' do
      expect do
        described_class.perform_later
      end.to have_enqueued_job(described_class).on_queue('scheduled_jobs')
    end
  end

  describe '#perform' do
    let(:mailer_double) { double }
    let(:delivery_double) { double(deliver_later: true) }

    before do
      allow(BillingMailer).to receive(:with).and_return(mailer_double)
      allow(mailer_double).to receive(:trial_expiring).and_return(delivery_double)
      allow(mailer_double).to receive(:trial_expired).and_return(delivery_double)
      allow(mailer_double).to receive(:usage_warning).and_return(delivery_double)
    end

    context 'with expiring trials' do
      it 'sends trial_expiring for trials ending within 3 days' do
        grant_trial(account, days: 2)

        described_class.perform_now

        expect(BillingMailer).to have_received(:with).with(account: account)
        expect(mailer_double).to have_received(:trial_expiring)
      end

      it 'does not send for trials ending more than 3 days out' do
        grant_trial(account, days: 10)

        described_class.perform_now

        expect(mailer_double).not_to have_received(:trial_expiring)
      end
    end

    context 'with expired trials' do
      it 'sends trial_expired for trials that ended yesterday' do
        grant_trial(account, days: 1)
        # Simulate trial ending yesterday — status must be non-active for the query
        sub = account.active_subscription
        sub.update!(trial_ends_at: 1.day.ago, ends_at: 1.day.ago, status: 'canceled')

        described_class.perform_now

        expect(BillingMailer).to have_received(:with).with(account: account)
        expect(mailer_double).to have_received(:trial_expired)
      end

      it 'does not send for trials that expired long ago' do
        grant_trial(account, days: 1)
        sub = account.active_subscription
        sub.update!(trial_ends_at: 10.days.ago, ends_at: 10.days.ago, status: 'canceled')

        described_class.perform_now

        expect(mailer_double).not_to have_received(:trial_expired)
      end
    end

    context 'with high usage accounts' do
      it 'sends usage_warning for accounts above 80% usage' do
        grant_subscription(account, plan_key: 'pro_monthly')
        plan = account.active_plan
        # Set usage to 85% of limit
        high_count = (plan.ai_response_limit * 0.85).to_i
        account.current_usage.update!(ai_responses_count: high_count)

        described_class.perform_now

        expect(BillingMailer).to have_received(:with).with(account: account)
        expect(mailer_double).to have_received(:usage_warning)
      end

      it 'does not send for accounts below 80% usage' do
        grant_subscription(account, plan_key: 'pro_monthly')
        account.current_usage.update!(ai_responses_count: 100)

        described_class.perform_now

        expect(mailer_double).not_to have_received(:usage_warning)
      end

      it 'does not send for accounts without a plan' do
        account.current_usage.update!(ai_responses_count: 50_000)

        described_class.perform_now

        expect(mailer_double).not_to have_received(:usage_warning)
      end
    end
  end
end
