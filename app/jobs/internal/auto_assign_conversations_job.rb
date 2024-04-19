class Internal::AutoAssignConversationsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Digitaltolk::AutoAssignConversationService.new.perform
  end
end
