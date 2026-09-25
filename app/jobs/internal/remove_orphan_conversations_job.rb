# housekeeping
# remove conversations that do not have a contact_id
# orphan conversations without contact cannot be accessed or used

class Internal::RemoveOrphanConversationsJob < ApplicationJob
  queue_as :within_1_day

  def perform
    Internal::RemoveOrphanConversationsService.new.perform
  end
end
