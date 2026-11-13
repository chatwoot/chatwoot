class SearchIndexingMaintenanceJob < ApplicationJob
  queue_as :search_backfill

  def perform
    return unless ChatwootApp.advanced_search_allowed?

    SearchIndexing::MaintenanceJob.perform_later
  end
end
