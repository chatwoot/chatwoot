class Captain::Documents::ScheduleSyncsJob < ApplicationJob
  queue_as :scheduled_jobs

  DEFAULT_PER_ACCOUNT_HOURLY_CAP = 50
  DEFAULT_GLOBAL_HOURLY_CAP = 1000
  SYNC_STALE_TIMEOUT = Captain::Document::SYNC_STALE_TIMEOUT
  DAILY_SYNC_JITTER = 4.hours
  WEEKLY_SYNC_JITTER = 1.day
  MONTHLY_SYNC_JITTER = 4.days

  def perform
    @per_account_hourly_cap = configured_sync_limit('CAPTAIN_DOCUMENT_AUTO_SYNC_PER_ACCOUNT_HOURLY_CAP', DEFAULT_PER_ACCOUNT_HOURLY_CAP)
    @global_hourly_cap = configured_sync_limit('CAPTAIN_DOCUMENT_AUTO_SYNC_GLOBAL_HOURLY_CAP', DEFAULT_GLOBAL_HOURLY_CAP)
    @remaining_global_capacity = @global_hourly_cap
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
    per_account_limit = [@per_account_hourly_cap, @remaining_global_capacity].min
    result = { enqueued: 0, skipped: 0 }
    skipped_document_ids = []

    while result[:enqueued] < per_account_limit

      documents = due_documents(account, interval, skipped_document_ids).limit(due_document_candidate_limit).to_a
      break if documents.empty?

      documents.each do |document|
        break if result[:enqueued] >= per_account_limit

        process_due_document(document, interval, result, skipped_document_ids)
      end
    end

    result
  end

  def process_due_document(document, interval, result, skipped_document_ids)
    return unless document.syncable?

    sync_execution_delay = sync_jitter(interval)

    # Reserve the sync slot before enqueueing so later scheduler runs skip this document while the job is queued.
    unless reserve_sync_slot(document, sync_execution_delay)
      result[:skipped] += 1
      skipped_document_ids << document.id
      return
    end

    Captain::Documents::PerformSyncJob.set(queue: :purgable, wait: sync_execution_delay).perform_later(document)
    @remaining_global_capacity -= 1
    result[:enqueued] += 1
  end

  def due_documents(account, interval, skipped_document_ids)
    syncing = Captain::Document.sync_statuses[:syncing]
    synced = Captain::Document.sync_statuses[:synced]
    failed = Captain::Document.sync_statuses[:failed]
    stale_cutoff = SYNC_STALE_TIMEOUT.ago
    due_cutoff = interval.ago

    documents = account.captain_documents.syncable.where(status: :available).where(
      '(sync_status = ? AND last_synced_at < ?) OR (sync_status = ? AND last_sync_attempted_at < ?) OR ' \
      '(sync_status = ? AND last_sync_attempted_at < ?)',
      synced, due_cutoff, failed, due_cutoff, syncing, stale_cutoff
    )
    documents = documents.where.not(id: skipped_document_ids) if skipped_document_ids.present?
    documents.order(Arel.sql('last_sync_attempted_at ASC NULLS FIRST'), :id)
  end

  def configured_sync_limit(config_key, default)
    configured_value = InstallationConfig.find_by(name: config_key)&.value
    limit = configured_value.to_s.to_i
    limit.positive? ? limit : default
  end

  def due_document_candidate_limit
    # Fetch twice the enqueue cap so skipped legacy rows do not prevent filling the account quota.
    @per_account_hourly_cap * 2
  end

  def reserve_sync_slot(document, sync_execution_delay)
    mark_sync_scheduled(document, sync_execution_delay)
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

  def sync_jitter(interval)
    jitter_window = if interval <= 1.day
                      DAILY_SYNC_JITTER
                    elsif interval <= 1.week
                      WEEKLY_SYNC_JITTER
                    else
                      MONTHLY_SYNC_JITTER
                    end

    rand(0..jitter_window.to_i).seconds
  end

  def log_scheduler_summary(stats)
    payload = {
      event: 'completed',
      global_cap_hit: @remaining_global_capacity <= 0,
      per_account_hourly_cap: @per_account_hourly_cap,
      global_hourly_cap: @global_hourly_cap,
      remaining_global_capacity: @remaining_global_capacity
    }.merge(stats)

    Rails.logger.info("[Captain::Documents::ScheduleSyncsJob] #{payload.to_json}")
  end

  def mark_sync_scheduled(document, sync_execution_delay)
    # Use the scheduled execution time so stale-lock recovery does not duplicate delayed jobs before they run.
    document.update!(
      sync_status: :syncing,
      sync_step: nil,
      last_sync_error_code: nil,
      last_sync_attempted_at: Time.current + sync_execution_delay
    )
  end
end
