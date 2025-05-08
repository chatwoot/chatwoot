# housekeeping
# remove contact inboxes that does not have any conversations
# and are older than 3 months

class Internal::RemoveStaleContactInboxesJob < ApplicationJob
  queue_as :low

  def perform
    Internal::RemoveStaleContactInboxesService.new.perform
  end
end
