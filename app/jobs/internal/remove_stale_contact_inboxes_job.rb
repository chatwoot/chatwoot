# housekeeping
# remove contact inboxes that does not have any conversations
# and are older than 3 months

class Internal::RemoveStaleContactInboxesJob < ApplicationJob
  queue_as :within_10_minutes

  def perform
    Internal::RemoveStaleContactInboxesService.new.perform
  end
end
