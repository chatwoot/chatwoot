class Captain::Documents::ScheduleSyncsJob < ApplicationJob
  queue_as :scheduled_jobs

  PER_ACCOUNT_HOURLY_CAP = 50
  GLOBAL_HOURLY_CAP = 1000
  SYNC_STALE_TIMEOUT = Captain::Document::SYNC_STALE_TIMEOUT

  def perform
    @remaining_global_capacity = GLOBAL_HOURLY_CAP
    sync_intervals = Enterprise::Account.captain_document_sync_intervals
    stats = { accounts_scanned: 0, accounts_enabled: 0, accounts_scheduled: 0, documents_enqueued: 0 }

    Account.joins(:captain_documents).distinct.find_each(batch_size: 100) do |account|
      break if @remaining_global_capacity <= 0

      stats[:accounts_scanned] += 1
      next unless account.feature_enabled?('captain_document_auto_sync')

      stats[:accounts_enabled] += 1
      interval = account.captain_document_sync_interval(sync_intervals)
      next unless interval

      stats[:accounts_scheduled] += 1
      stats[:documents_enqueued] += enqueue_due_documents(account, interval)
    end

    log_scheduler_summary(stats)
  end

  private

  def enqueue_due_documents(account, interval)
    syncing = Captain::Document.sync_statuses[:syncing]
    synced = Captain::Document.sync_statuses[:synced]
    failed = Captain::Document.sync_statuses[:failed]
    stale_cutoff = SYNC_STALE_TIMEOUT.ago
    per_account_limit = [PER_ACCOUNT_HOURLY_CAP, @remaining_global_capacity].min
    enqueued_count = 0

    account.captain_documents.syncable.where(status: :available).where(
      '(sync_status = ? AND last_synced_at < ?) OR (sync_status = ? AND last_sync_attempted_at < ?) OR ' \
      '(sync_status = ? AND last_sync_attempted_at < ?)',
      synced, interval.ago, failed, interval.ago, syncing, stale_cutoff
    ).order(Arel.sql('last_sync_attempted_at ASC NULLS FIRST'), :id).limit(per_account_limit).each do |document|
      next unless document.syncable?

      # Reserve the sync slot before enqueueing so later scheduler runs skip this document while the job is queued.
      document.update!(sync_status: :syncing, last_sync_attempted_at: Time.current)
      Captain::Documents::PerformSyncJob.perform_later(document)
      @remaining_global_capacity -= 1
      enqueued_count += 1
    end

    enqueued_count
  end

  def log_scheduler_summary(stats)
    payload = {
      event: 'completed',
      global_cap_hit: @remaining_global_capacity <= 0,
      remaining_global_capacity: @remaining_global_capacity
    }.merge(stats)

    Rails.logger.info("[Captain::Documents::ScheduleSyncsJob] #{payload.to_json}")
  end
end
