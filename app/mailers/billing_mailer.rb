# Mailer for billing-related notifications.
# Inherits the Liquid template infrastructure from AdministratorNotifications::BaseMailer.
# All methods send to account administrators by default.
#
# Usage:
#   BillingMailer.with(account: account).trial_expiring(account, days_remaining: 3).deliver_later
#
class BillingMailer < AdministratorNotifications::BaseMailer
  def trial_expiring(account, days_remaining:)
    subject = "Your AlooChat trial ends in #{days_remaining} days"
    action_url = billing_url(account)
    meta = {
      'account_name' => account.name,
      'days_remaining' => days_remaining.to_s,
      'plan_name' => account.active_plan&.name || 'Pro'
    }

    send_notification(subject, action_url: action_url, meta: meta)
  end

  def trial_expired(account)
    subject = 'Your AlooChat trial has ended'
    action_url = billing_url(account)
    meta = { 'account_name' => account.name }

    send_notification(subject, action_url: action_url, meta: meta)
  end

  def payment_failed(account)
    subject = 'Action required: payment failed'
    action_url = billing_url(account)
    meta = {
      'account_name' => account.name,
      'plan_name' => account.active_plan&.name
    }

    send_notification(subject, action_url: action_url, meta: meta)
  end

  def usage_warning(account, percentage:)
    subject = "You've used #{percentage}% of your AI responses"
    action_url = billing_url(account)
    usage = account.usage_summary
    meta = {
      'account_name' => account.name,
      'percentage' => percentage.to_s,
      'ai_responses_count' => usage[:ai_responses_count].to_s,
      'ai_responses_limit' => usage[:ai_responses_limit].to_s
    }

    send_notification(subject, action_url: action_url, meta: meta)
  end

  def overage_notice(account, overage_count:)
    subject = "AI overage: #{overage_count} responses will be billed"
    action_url = billing_url(account)
    meta = {
      'account_name' => account.name,
      'overage_count' => overage_count.to_s,
      'overage_cost' => format('%.3f', overage_count * 0.010)
    }

    send_notification(subject, action_url: action_url, meta: meta)
  end

  def usage_limit_reached(account)
    subject = 'Monthly AI response limit reached'
    action_url = billing_url(account)
    meta = {
      'account_name' => account.name,
      'plan_name' => account.active_plan&.name
    }

    send_notification(subject, action_url: action_url, meta: meta)
  end

  def welcome_to_plan(account)
    plan = account.active_plan
    subject = "Welcome to AlooChat #{plan&.name || 'Pro'}!"
    action_url = billing_url(account)
    meta = {
      'account_name' => account.name,
      'plan_name' => plan&.name
    }

    send_notification(subject, action_url: action_url, meta: meta)
  end

  def plan_changed(account, old_plan_name:)
    new_plan = account.active_plan
    subject = 'Your AlooChat plan has been updated'
    action_url = billing_url(account)
    meta = {
      'account_name' => account.name,
      'old_plan_name' => old_plan_name,
      'new_plan_name' => new_plan&.name
    }

    send_notification(subject, action_url: action_url, meta: meta)
  end

  def account_suspended(account)
    subject = 'Account suspended — update payment method'
    action_url = billing_url(account)
    meta = { 'account_name' => account.name }

    send_notification(subject, action_url: action_url, meta: meta)
  end

  def account_reactivated(account)
    subject = 'Account reactivated'
    action_url = billing_url(account)
    meta = { 'account_name' => account.name }

    send_notification(subject, action_url: action_url, meta: meta)
  end

  private

  def billing_url(account)
    "#{ENV.fetch('FRONTEND_URL', '')}/app/accounts/#{account.id}/settings/billing"
  end
end
