class FailedEmailRetryBatchJob < ApplicationJob
  queue_as :low

  def perform(batch_id)
    batch = FailedEmailRetryBatch.find_by(id: batch_id)
    return if batch.blank?

    return unless claim_batch(batch)

    @scheduled_count = 0
    @skipped_count = 0
    @error_count = 0
    process_batch(batch)
  rescue StandardError => e
    fail_batch(batch, e)
  end

  private

  def claim_batch(batch)
    batch.with_lock do
      next false unless batch.queued?

      batch.update!(status: :processing, started_at: Time.current, error_message: nil)
      true
    end
  end

  def process_batch(batch)
    candidates = batch.candidates
    @skipped_count = [batch.candidate_count - candidates.count, 0].max
    candidates.includes(:account).find_each { |message| process_message(message) }

    complete_batch(batch)
  end

  def complete_batch(batch)
    accounted_for_count = @scheduled_count + @skipped_count + @error_count
    @skipped_count += [batch.candidate_count - accounted_for_count, 0].max

    batch.update!(
      status: :completed,
      scheduled_count: @scheduled_count,
      skipped_count: @skipped_count,
      error_count: @error_count,
      completed_at: Time.current
    )
    log_result(batch)
  end

  def process_message(message)
    if message.account.suspended?
      @skipped_count += 1
      return
    end

    if Messages::RetryService.new(message, wait: retry_delay).perform
      @scheduled_count += 1
    else
      @skipped_count += 1
    end
  rescue StandardError => e
    @error_count += 1
    Rails.logger.error("[FailedEmailRetryBatch] message_id=#{message.id} error=#{e.class}: #{e.message}")
  end

  def retry_delay
    rand(1.minute.to_i..2.hours.to_i).seconds
  end

  def fail_batch(batch, error)
    batch&.update(
      status: :failed,
      scheduled_count: @scheduled_count || batch.scheduled_count,
      skipped_count: @skipped_count || batch.skipped_count,
      error_count: @error_count || batch.error_count,
      completed_at: Time.current,
      error_message: I18n.t('super_admin.failed_email_retries.batch_failed')
    )
    log_result(batch) if batch
    ChatwootExceptionTracker.new(error).capture_exception
  end

  def log_result(batch)
    Rails.logger.info(
      "[SuperAdmin] failed email retry batch=#{batch.id} actor_id=#{batch.requested_by_id} " \
      "actor_email=#{batch.requested_by.email} status=#{batch.status} candidates=#{batch.candidate_count} " \
      "scheduled=#{batch.scheduled_count} skipped=#{batch.skipped_count} errors=#{batch.error_count}"
    )
  end
end
