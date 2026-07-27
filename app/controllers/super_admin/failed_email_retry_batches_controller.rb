class SuperAdmin::FailedEmailRetryBatchesController < SuperAdmin::ApplicationController
  def show
    batch = FailedEmailRetryBatch.find(params[:id])
    render json: status_payload(batch)
  end

  def create
    lookback_hours = params[:lookback_hours].to_i
    return redirect_invalid_lookback unless FailedEmailRetryBatch::LOOKBACK_HOURS.include?(lookback_hours)

    preview = FailedEmailRetryBatch.preview_for(lookback_hours: lookback_hours)
    return redirect_empty_preview(lookback_hours) if preview[:eligible_count].zero?

    batch = create_batch(lookback_hours, preview)
    enqueue_batch(batch)
    redirect_to_batch(batch)
  rescue ActiveRecord::RecordNotUnique
    redirect_to_active_batch
  rescue StandardError => e
    handle_enqueue_failure(batch, e)
  end

  private

  def create_batch(lookback_hours, preview)
    FailedEmailRetryBatch.create!(
      requested_by: current_super_admin,
      lookback_hours: lookback_hours,
      range_start: preview[:range_start],
      range_end: preview[:range_end],
      candidate_count: preview[:candidate_count],
      eligible_count: preview[:eligible_count]
    )
  end

  def enqueue_batch(batch)
    job = FailedEmailRetryBatchJob.perform_later(batch.id)
    return if job.successfully_enqueued?

    raise ActiveJob::EnqueueError, "Could not enqueue failed email retry batch #{batch.id}"
  end

  def redirect_to_batch(batch)
    redirect_to super_admin_app_config_path(
      config: 'internal',
      lookback_hours: batch.lookback_hours,
      failed_email_retry_batch_id: batch.id
    ), notice: I18n.t('super_admin.failed_email_retries.queued_notice', count: batch.eligible_count)
  end

  def redirect_invalid_lookback
    redirect_to super_admin_app_config_path(config: 'internal'),
                alert: I18n.t('super_admin.failed_email_retries.invalid_lookback')
  end

  def redirect_empty_preview(lookback_hours)
    redirect_to super_admin_app_config_path(config: 'internal', lookback_hours: lookback_hours),
                alert: I18n.t('super_admin.failed_email_retries.empty_state')
  end

  def redirect_to_active_batch
    active_batch = FailedEmailRetryBatch.where(status: [:queued, :processing]).order(created_at: :asc).first ||
                   FailedEmailRetryBatch.order(created_at: :desc).first
    redirect_to super_admin_app_config_path(
      config: 'internal',
      lookback_hours: active_batch.lookback_hours,
      failed_email_retry_batch_id: active_batch.id
    ), alert: I18n.t('super_admin.failed_email_retries.batch_in_progress')
  end

  def handle_enqueue_failure(batch, error)
    batch&.update(
      status: :failed,
      completed_at: Time.current,
      error_message: I18n.t('super_admin.failed_email_retries.batch_failed')
    )
    ChatwootExceptionTracker.new(error, user: current_super_admin).capture_exception
    redirect_to super_admin_app_config_path(config: 'internal'),
                alert: I18n.t('super_admin.failed_email_retries.enqueue_failed')
  end

  def status_payload(batch)
    {
      id: batch.id,
      status: batch.status,
      status_label: I18n.t("super_admin.failed_email_retries.statuses.#{batch.status}"),
      lookback_hours: batch.lookback_hours,
      range_start: batch.range_start.iso8601,
      range_end: batch.range_end.iso8601,
      candidate_count: batch.candidate_count,
      eligible_count: batch.eligible_count,
      scheduled_count: batch.scheduled_count,
      skipped_count: batch.skipped_count,
      error_count: batch.error_count,
      created_at: batch.created_at.iso8601,
      started_at: batch.started_at&.iso8601,
      completed_at: batch.completed_at&.iso8601,
      completed_at_label: batch.completed_at && I18n.l(batch.completed_at, format: :long),
      error_message: batch.error_message,
      active: batch.active?
    }
  end
end
