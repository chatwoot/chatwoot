# frozen_string_literal: true

# Runs daily via sidekiq-cron to alert accounts approaching their AI token limit.
# Sends alerts at 80% and 100% usage thresholds (once per threshold per billing period).
class Saas::UsageAlertJob < ApplicationJob
  queue_as :low

  THRESHOLDS = [80, 100].freeze

  def perform
    Saas::Subscription.where(status: %i[active trialing])
                      .includes(:plan, :account)
                      .find_each do |subscription|
      account = subscription.account
      plan = subscription.plan
      next unless plan&.ai_tokens_monthly&.positive?

      percentage = account.ai_usage_percentage
      check_thresholds(account, percentage, subscription)
    end
  end

  private

  def check_thresholds(account, percentage, subscription)
    THRESHOLDS.each do |threshold|
      next unless percentage >= threshold

      cache_key = usage_alert_cache_key(account, threshold, subscription)
      next if Rails.cache.read(cache_key)

      Saas::BillingMailer.usage_alert(account, threshold).deliver_later

      # Don't send the same threshold alert again this billing period
      ttl = subscription.current_period_end ? (subscription.current_period_end - Time.current).to_i.seconds : 30.days
      Rails.cache.write(cache_key, true, expires_in: ttl)
    end
  end

  def usage_alert_cache_key(account, threshold, subscription)
    period = subscription.current_period_start&.strftime('%Y%m%d') || 'default'
    "saas:usage_alert:#{account.id}:#{period}:#{threshold}"
  end
end
