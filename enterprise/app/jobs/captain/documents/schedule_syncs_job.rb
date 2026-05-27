class Captain::Documents::ScheduleSyncsJob < ApplicationJob
  queue_as :scheduled_jobs

  DEFAULT_PER_ACCOUNT_BATCH_LIMIT = 50
  DEFAULT_GLOBAL_BATCH_LIMIT = 1000
  SYNC_STALE_TIMEOUT = Captain::Document::SYNC_STALE_TIMEOUT
  DAILY_SYNC_JITTER = 4.hours
  WEEKLY_SYNC_JITTER = 1.day
  MONTHLY_SYNC_JITTER = 4.days

  def perform(plan_name = nil)
    @per_account_batch_limit = configured_sync_limit('CAPTAIN_DOCUMENT_AUTO_SYNC_PER_ACCOUNT_BATCH_LIMIT', DEFAULT_PER_ACCOUNT_BATCH_LIMIT)
    @global_batch_limit = configured_sync_limit('CAPTAIN_DOCUMENT_AUTO_SYNC_GLOBAL_BATCH_LIMIT', DEFAULT_GLOBAL_BATCH_LIMIT)
    @remaining_global_capacity = @global_batch_limit
    @plan_name = plan_name.to_s.downcase.presence
    sync_intervals = Enterprise::Account.captain_document_sync_intervals
    stats = { accounts_scanned: 0, accounts_enabled: 0, accounts_scheduled: 0, documents_enqueued: 0 }

    Account.joins(:captain_documents).distinct.find_each(batch_size: 100) do |account|
      break if @remaining_global_capacity <= 0

      stats[:accounts_scanned] += 1
      next unless account.feature_enabled?('captain_document_auto_sync')
      next unless account_in_selected_plan?(account)

      stats[:accounts_enabled] += 1
      interval = account.captain_document_sync_interval(sync_intervals)
      next unless interval

      stats[:accounts_scheduled] += 1
      result = enqueue_due_documents(account, interval)
      stats[:documents_enqueued] += result[:enqueued]
    end

    log_scheduler_summary(stats)
  end

  private

  def enqueue_due_documents(account, interval)
    per_account_limit = [@per_account_batch_limit, @remaining_global_capacity].min
    result = { enqueued: 0 }

    due_documents(account, interval).limit(per_account_limit).to_a.each do |document|
      process_due_document(document, interval, result)
    end

    result
  end

  def process_due_document(document, interval, result)
    sync_execution_delay = sync_jitter(interval)

    Captain::Documents::PerformSyncJob.set(queue: :purgable, wait: sync_execution_delay).perform_later(document)
    @remaining_global_capacity -= 1
    result[:enqueued] += 1
  end

  def due_documents(account, interval)
    syncing = Captain::Document.sync_statuses[:syncing]
    synced = Captain::Document.sync_statuses[:synced]
    failed = Captain::Document.sync_statuses[:failed]
    stale_cutoff = SYNC_STALE_TIMEOUT.ago
    # The scheduler runs at predictable plan windows. Use a wider due window so
    # jittered executions do not miss the next window just because they finished later.
    sync_due_before = due_window(interval).ago

    documents = account.captain_documents.syncable.where(status: :available).where(
      '(sync_status = ? AND last_synced_at < ?) OR (sync_status = ? AND last_sync_attempted_at < ?) OR ' \
      '(sync_status = ? AND last_sync_attempted_at < ?)',
      synced, sync_due_before, failed, sync_due_before, syncing, stale_cutoff
    )
    documents.order(Arel.sql('last_sync_attempted_at ASC NULLS FIRST'), :id)
  end

  def configured_sync_limit(config_key, default)
    configured_value = InstallationConfig.find_by(name: config_key)&.value
    limit = configured_value.to_s.to_i
    limit.positive? ? limit : default
  end

  def account_in_selected_plan?(account)
    return true if @plan_name.blank?

    account_sync_plan(account) == @plan_name
  end

  def account_sync_plan(account)
    plan = account.custom_attributes['plan_name']
    plan = 'enterprise' if plan.blank? && ChatwootApp.self_hosted_enterprise?
    plan.to_s.downcase.presence
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

  def due_window(interval)
    (interval.to_i / 2).seconds
  end

  def log_scheduler_summary(stats)
    payload = {
      event: 'completed',
      plan_name: @plan_name,
      global_cap_hit: @remaining_global_capacity <= 0,
      per_account_batch_limit: @per_account_batch_limit,
      global_batch_limit: @global_batch_limit,
      remaining_global_capacity: @remaining_global_capacity
    }.merge(stats)

    Rails.logger.info("[Captain::Documents::ScheduleSyncsJob] #{payload.to_json}")
  end
end
