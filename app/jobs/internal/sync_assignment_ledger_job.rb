class Internal::SyncAssignmentLedgerJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    SalesRouting::SyncAssignmentsJob.perform_later if ChatwootApp.enterprise?
  end
end
