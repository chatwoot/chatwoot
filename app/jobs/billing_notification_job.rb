# Daily job that sends billing notifications for:
#   - Trials expiring within 3 days
#   - Trials that expired yesterday
#   - Accounts exceeding 80% AI usage
#
# Scheduled via sidekiq-cron (see config/schedule.yml).
# Can also be run manually: BillingNotificationJob.perform_now
#
class BillingNotificationJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    notify_expiring_trials
    notify_expired_trials
    notify_high_usage
  end

  private

  def notify_expiring_trials
    expiring_subs = Pay::Subscription.where(
      trial_ends_at: Time.current..3.days.from_now
    ).where(status: %w[active trialing])

    expiring_subs.find_each do |sub|
      account = sub.customer&.owner
      next unless account.is_a?(Account)

      days = ((sub.trial_ends_at - Time.current) / 1.day).ceil
      BillingMailer.with(account: account).trial_expiring(account, days_remaining: days).deliver_later
    end
  end

  def notify_expired_trials
    expired_subs = Pay::Subscription.where(
      trial_ends_at: 2.days.ago..Time.current
    ).where.not(status: %w[active trialing])

    expired_subs.find_each do |sub|
      account = sub.customer&.owner
      next unless account.is_a?(Account)

      BillingMailer.with(account: account).trial_expired(account).deliver_later
    end
  end

  def notify_high_usage
    Account.where(status: :active).find_each do |account|
      plan = account.active_plan
      next unless plan

      usage = account.current_usage
      limit = plan.ai_response_limit
      next unless limit.positive?

      percentage = (usage.ai_responses_count.to_f / limit * 100).round(1)
      next unless percentage >= 80

      if usage.overage_count.positive?
        BillingMailer.with(account: account).overage_notice(account, overage_count: usage.overage_count).deliver_later
      else
        BillingMailer.with(account: account).usage_warning(account, percentage: percentage).deliver_later
      end
    end
  end
end
