# housekeeping
# ensure stale ONLINE PRESENCE KEYS for contacts are removed periodically
# should result in 50% redis mem size reduction

class Internal::RemoveStaleRedisKeysJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Account.find_each do |account|
      Rails.logger.info "Enqueuing ProcessStaleRedisKeysJob for account #{account.id}"
      Internal::ProcessStaleRedisKeysJob.perform_later(account)
    end
  end
end
