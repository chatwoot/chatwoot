module ChatwootGlpiIntegration
  # Cron job: re-sync every active link in the account.
  # Recommended schedule: every 5 minutes via sidekiq-cron / sidekiq-scheduler.
  class ReconcileAllJob < ::ApplicationJob
    queue_as :integrations

    def perform(account_id = nil)
      scope = TicketLink.active_sync
      scope = scope.where(account_id: account_id) if account_id

      scope.find_each do |link|
        SyncTicketJob.perform_later(link.id)
      end
    end
  end
end
