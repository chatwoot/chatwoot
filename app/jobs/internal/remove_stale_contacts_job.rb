# housekeeping
# remove contacts that:
# - have no identification (email, phone_number, and identifier are NULL)
# - have no conversations
# - are older than 30 days

class Internal::RemoveStaleContactsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Internal::RemoveStaleContactsService.new.perform
  end
end
