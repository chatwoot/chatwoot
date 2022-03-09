class Account::EmailDigestJob
  queue_as :default

  def perform(accounts:)
    return if accounts.empty?

    accounts.each do |account|
      account_users = account.users

      next if account_users.empty?

      account_users.each do |user|
        return unless user_subscribed_to_notification?(user)

        Notification::EmailDigestService.new(user, account).perform
      end
    end
  end

  private

  def user_subscribed_to_notification?(user)
    user.email_digest_enabled?
  end
end
