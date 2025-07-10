class NotifyUpcomingExpiryUser < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info('[NotifyUpcomingExpiryUser] Starting job to process upcoming expiry')

    Timeout.timeout(1.hour.second) do
      loop do
        upcoming_expiry_subscriptions = fetch_upcoming_expiry_subscriptions

        if upcoming_expiry_subscriptions.blank?
          Rails.logger.info('No more upcoming expiry subscriptions, skipping.')
          break
        end

        ActiveRecord::Base.transaction do
          upcoming_expiry_subscriptions.each do |upcoming_expiry|
            # Rails.logger.info("id: #{upcoming_expiry.subscriptions.first.id}. last_notify: #{upcoming_expiry.subscriptions.first.last_notify_expiry}. ends_at #{upcoming_expiry.subscriptions.first.ends_at}. Data #{upcoming_expiry.users.first.email}. role #{upcoming_expiry.account_users.first.role}")
            subscription = Subscription.find_by(id: upcoming_expiry.subscriptions.first.id)
            next if subscription.nil?

            user = upcoming_expiry.users.first

            SubscriptionNotifierMailer.upcoming_expiry(
              user.email,
              subscription.account_id,
              Time.now.utc.strftime('%d %b %Y'),
              user.display_name || user.name,
              subscription.plan_name,
              subscription.ends_at.strftime('%d %b %Y')
            ).deliver_later
            subscription.last_notify_expiry = Time.now.utc
            subscription.save!
          end

          next
        end
      end
    rescue Timeout::Error
      log_error("NotifyUpcomingLoop", "Operation timed out")
    end

    Rails.logger.info("[NotifyUpcomingExpiryUser] Finished processing upcoming expiry")
  end

  private

  def fetch_upcoming_expiry_subscriptions
    Account.joins('left join "subscriptions" on subscriptions.id = "accounts"."active_subscription_id"')
      .joins('left join "account_users" on "account_users"."account_id" = "accounts"."id"')
      .joins('left join "users" on "users"."id" = "account_users"."user_id"')
      .where(subscriptions: { last_notify_expiry: nil })
      .where('DATE(subscriptions.ends_at) = DATE(?)', 7.days.from_now)
      .where('"account_users"."role" = ?', AccountUser.roles[:administrator])
      .where.not(active_subscription_id: nil)
      .limit(10)
  end

  def log_error(action, exception)
    Rails.logger.error("[NotifyUpcomingExpiryUser] #{action} failed for: #{exception.message}")
  end
end
