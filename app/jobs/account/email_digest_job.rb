class Account::EmailDigestJob
  queue_as :default

  def perform(accounts:)
    return if accounts.empty?

    accounts.each do |account|
      account_users = account.users

      next if account_users.empty?

      account_users.each do |user|
        Notification::EmailDigestService.new(user, account).perform
      end
    end
  end
end
