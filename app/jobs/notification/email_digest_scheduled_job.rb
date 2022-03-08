class Notification::EmailDigestScheduledJob
  queue_as :scheduled_jobs

  # Send email to customer about the recent chatwoot metrics
  def perform
    return if Account.count.zero?

    accounts = Account.all
    accounts.find_in_batches do |account_batch|
      Account::EmailDigestJob.new.perform_later(accounts: account_batch)
    end
  end
end
