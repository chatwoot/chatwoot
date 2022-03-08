class Account::EmailDigestJob
  queue_as :default

  def perform(accounts:)
    return if accounts.empty?

    accounts.each do |account|
      account_users = account.users

      next if account_users.empty?

      account_users.each do |user|
        return unless user_subscribed_to_notification?(user, account)

        Notification::EmailDigestService.new(user, account).perform
      end
    end
  end

  private

  def user_subscribed_to_notification?(user, account)
    notification_setting = user.notification_settings.find_by(account_id: account.id)
    # return true if notification_setting.public_send("email_email_digest")

    true
  end
end
