# housekeeping
# close conversations that are already stale

class Internal::RemoveStaleConversationsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Digitaltolk::CloseResolvedConversationService.new.perform
  end
end
