# housekeeping
# remove contact inboxes that does not have any conversations
# and are older than 3 months

class Internal::ProcessStaleRedisKeysJob < ApplicationJob
  queue_as :low

  def perform(account)
    Internal::RemoveStaleRedisKeysService.new(account_id: account.id).perform
  end
end
