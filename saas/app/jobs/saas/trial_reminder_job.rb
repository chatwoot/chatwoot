# frozen_string_literal: true

# Runs daily via sidekiq-cron to send trial expiration reminders.
# Sends reminders at 3 days and 1 day before trial ends.
class Saas::TrialReminderJob < ApplicationJob
  queue_as :low

  def perform
    remind_at_days = [3, 1]

    remind_at_days.each do |days_before|
      target_date = days_before.days.from_now.to_date

      Saas::Subscription.where(status: :trialing)
                        .where('DATE(trial_end) = ?', target_date)
                        .includes(:account)
                        .find_each do |subscription|
        Saas::BillingMailer.trial_expiring(subscription.account).deliver_later
      end
    end
  end
end
