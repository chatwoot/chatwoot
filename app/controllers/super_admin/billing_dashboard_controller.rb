# Super admin billing dashboard showing key subscription metrics.
# Computes aggregate stats from Pay tables and Account status.
#
class SuperAdmin::BillingDashboardController < SuperAdmin::ApplicationController
  include ActionView::Helpers::NumberHelper

  def show
    @metrics = gather_metrics
  end

  private

  def gather_metrics
    {
      active_subscriptions: active_subscriptions_count,
      trials: trials_count,
      trials_expiring_7_days: trials_expiring_soon_count,
      complimentary: complimentary_count,
      no_subscription: no_subscription_count,
      suspended: suspended_count,
      total_accounts: Account.count
    }
  end

  def active_subscriptions_count
    Pay::Subscription.where(status: 'active').count
  end

  def trials_count
    Pay::Subscription.where('trial_ends_at > ?', Time.current).count
  end

  def trials_expiring_soon_count
    Pay::Subscription.where(trial_ends_at: Time.current..7.days.from_now).count
  end

  def complimentary_count
    Pay::Customer.where(processor: 'fake_processor')
                 .joins('INNER JOIN pay_subscriptions ON pay_subscriptions.customer_id = pay_customers.id')
                 .where(pay_subscriptions: { status: 'active' })
                 .where('pay_subscriptions.trial_ends_at IS NULL OR pay_subscriptions.trial_ends_at < ?', Time.current)
                 .select('pay_customers.owner_id').distinct.count
  end

  def no_subscription_count
    Account.where.not(id: Pay::Customer.where(owner_type: 'Account').select(:owner_id)).count
  end

  def suspended_count
    Account.where(status: :suspended).count
  end
end
