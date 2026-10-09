# Ends calls that have rung past their provider's timeout; ringing timeouts are an
# Enterprise feature
class Internal::CheckRingingTimeoutsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Voice::RingingTimeoutJob.perform_now if ChatwootApp.enterprise?
  end
end
