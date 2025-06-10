class ResetSubscriptionUsageJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Subscription.active.find_each do |subscription|
      Rails.logger.info("[ResetSubscriptionUsageJob] [Fetch] Reset usage for Subscription ID: #{subscription.id}")
      next unless reset_due?(subscription)
      next unless subscription.ends_at.nil? || subscription.ends_at >= Time.zone.today

      usage = SubscriptionUsage.find_by(subscription_id: subscription.id)
      next unless usage

      usage.update(
        mau_count: 0,
        ai_responses_count: 0,
        last_reset_at: Time.current,
      )

      Rails.logger.info("[ResetSubscriptionUsageJob] Reset usage for Subscription ID: #{subscription.id}")
    end
  end

  private

  def reset_due?(subscription)
    return false unless subscription.starts_at.present?

    days_since_start = (Time.zone.today - subscription.starts_at.to_date).to_i
    days_since_start % 30 == 0
  end
end
