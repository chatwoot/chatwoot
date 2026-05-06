class Captain::Documents::ScheduleSyncsJob < ApplicationJob
  queue_as :scheduled_jobs

  PER_ACCOUNT_HOURLY_CAP = 50
  GLOBAL_HOURLY_CAP = 1000
  SYNC_STALE_TIMEOUT = Captain::Document::SYNC_STALE_TIMEOUT

  def perform
    @remaining_global_capacity = GLOBAL_HOURLY_CAP
    sync_intervals = Enterprise::Account.captain_document_sync_intervals
    stats = { accounts_scanned: 0, accounts_enabled: 0, accounts_scheduled: 0, documents_enqueued: 0, documents_skipped: 0 }

    Account.joins(:captain_documents).distinct.find_each(batch_size: 100) do |account|
      break if @remaining_global_capacity <= 0

      stats[:accounts_scanned] += 1
      next unless account.feature_enabled?('captain_document_auto_sync')

      stats[:accounts_enabled] += 1
      interval = account.captain_document_sync_interval(sync_intervals)
      next unless interval

      stats[:accounts_scheduled] += 1
      result = enqueue_due_documents(account, interval)
      stats[:documents_enqueued] += result[:enqueued]
      stats[:documents_skipped] += result[:skipped]
    end

    log_scheduler_summary(stats)
  end

  private

  def enqueue_due_documents(account, interval)
    per_account_limit = [PER_ACCOUNT_HOURLY_CAP, @remaining_global_capacity].min
    result = { enqueued: 0, skipped: 0 }

    due_documents(account, interval, per_account_limit).each do |document|
      next unless document.syncable?

      # Reserve the sync slot before enqueueing so later scheduler runs skip this document while the job is queued.
      unless reserve_sync_slot(document)
        result[:skipped] += 1
        next
      end

      Captain::Documents::PerformSyncJob.perform_later(document)
      @remaining_global_capacity -= 1
      result[:enqueued] += 1
    end

    result
  end

  def due_documents(account, interval, limit)
    syncing = Captain::Document.sync_statuses[:syncing]
    synced = Captain::Document.sync_statuses[:synced]
    failed = Captain::Document.sync_statuses[:failed]

    account.captain_documents.syncable.where(status: :available).where(
      '(sync_status = ? AND last_synced_at < ?) OR (sync_status = ? AND last_sync_attempted_at < ?) OR ' \
      '(sync_status = ? AND last_sync_attempted_at < ?)',
      synced, interval.ago, failed, interval.ago, syncing, SYNC_STALE_TIMEOUT.ago
    ).order(Arel.sql('last_sync_attempted_at ASC NULLS FIRST'), :id).limit(limit)
  end

  def reserve_sync_slot(document)
    document.update!(sync_status: :syncing, last_sync_attempted_at: Time.current)
    true
  rescue ActiveRecord::RecordInvalid => e
    log_document_skip(document, e)
    false
  end

  def log_document_skip(document, error)
    payload = {
      event: 'document_skipped',
      document_id: document.id,
      account_id: document.account_id,
      assistant_id: document.assistant_id,
      error_class: error.class.name,
      error_message: error.message,
      validation_errors: document.errors.full_messages
    }

    Rails.logger.warn("[Captain::Documents::ScheduleSyncsJob] #{payload.to_json}")
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
