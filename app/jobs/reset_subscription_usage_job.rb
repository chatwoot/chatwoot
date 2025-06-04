class ResetSubscriptionUsageJob < ApplicationJob
  queue_as :default

  def perform(*args)
    SubscriptionUsage.update_all(
      mau_count: 0,
      ai_responses_count: 0,
      last_reset_at: Time.current
    )
  end
end
