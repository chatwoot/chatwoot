class Captain::Documents::PerformSyncJob < MutexApplicationJob
  queue_as :low

  # A single page fetch + fingerprint compare should complete in seconds.
  # 10 minutes is generous headroom — if still "syncing" after that, the worker likely died mid-run.
  # Shared with ScheduleSyncsJob so stale locks are re-enqueued at the same threshold.
  LOCK_TIMEOUT = 10.minutes

  # Safety net for anything we didn't rescue by name — parser bugs, ActiveRecord blips,
  # random infra issues. Three attempts lets a real hiccup recover. The exhaustion block
  # absorbs the final exception so Sidekiq doesn't layer its own retry policy on top, and
  # is the single place we report to Sentry — handle_unexpected_failure logs but does not
  # capture, so a deterministic bug emits one Sentry event instead of one per attempt.
  # Goes first because retry_on handlers dispatch bottom-to-top.
  retry_on StandardError, wait: 5.seconds, attempts: 3 do |job, error|
    document = job.arguments.first
    ChatwootExceptionTracker.new(error, account: document.account).capture_exception
    job.send(:log_sync_outcome, document, result: :unexpected_retry_exhausted,
                                          error_code: 'sync_error',
                                          exception_class: error.class.name)
  end

  # Permanent errors (404, 403, empty content) — no point retrying, discard immediately.
  # Document is already marked failed by SyncService before the exception reaches here.
  discard_on(Captain::Documents::SyncService::PermanentSyncError)

  # TransientSyncError is raised by SyncService when the customer's site is unreachable —
  # timeouts, TLS errors, 5xx, connection drops. Four attempts with backoff gives the site
  # a chance to recover before we give up.
  #
  # The exhaustion block absorbs the exception so it doesn't propagate to Sentry —
  # site flakiness isn't an application bug.
  retry_on(
    Captain::Documents::SyncService::TransientSyncError,
    wait: ->(executions) { [30.seconds, 2.minutes, 5.minutes][executions - 1] || 5.minutes },
    attempts: 4
  ) do |job, error|
    document = job.arguments.first
    job.send(:log_sync_outcome, document, result: :transient_retry_exhausted, error_code: error.message)
  end

  discard_on ActiveJob::DeserializationError
  discard_on ActiveRecord::RecordNotFound

  def perform(document)
    start_time = Time.current
    return if document.pdf_document?

    with_lock(lock_key(document), LOCK_TIMEOUT) do
      document.update!(sync_status: :syncing, last_sync_attempted_at: Time.current)
      result = Captain::Documents::SyncService.new(document.reload).perform
      log_sync_outcome(document, result: result, duration_ms: duration_ms_since(start_time))
    end
  rescue LockAcquisitionError
    log_sync_outcome(document, result: :already_syncing)
  rescue Captain::Documents::SyncService::PermanentSyncError => e
    log_failure_and_raise(document, :permanent_failure, e, start_time)
  rescue Captain::Documents::SyncService::TransientSyncError => e
    log_failure_and_raise(document, :transient_failure, e, start_time)
  rescue StandardError => e
    handle_unexpected_failure(document, e, start_time)
  end

  private

  def log_sync_outcome(document, **fields)
    payload = {
      document_id: document.id,
      account_id: document.account_id,
      assistant_id: document.assistant_id
    }.merge(fields)
    Rails.logger.info("[Captain::Documents::PerformSyncJob] #{payload.to_json}")
  end

  def log_failure_and_raise(document, result, error, start_time)
    log_sync_outcome(document, result: result, error_code: error.message,
                               duration_ms: duration_ms_since(start_time))
    raise error
  end

  def handle_unexpected_failure(document, error, start_time)
    document.update!(
      sync_status: :failed,
      sync_step: nil,
      last_sync_error_code: 'sync_error',
      last_sync_attempted_at: Time.current
    )
    log_sync_outcome(document, result: :unexpected_failure, error_code: 'sync_error',
                               exception_class: error.class.name,
                               duration_ms: duration_ms_since(start_time))
    raise error
  end

  def lock_key(document)
    format(::Redis::Alfred::CAPTAIN_DOCUMENT_SYNC_MUTEX, document_id: document.id)
  end

  def duration_ms_since(start_time)
    ((Time.current - start_time) * 1000).round
  end
end
