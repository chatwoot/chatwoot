# housekeeping
# close conversations that are already stale

class Internal::CloseStaleConversationsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Digitaltolk::CloseResolvedConversationService.new(Account.first&.id).perform
  end
end
