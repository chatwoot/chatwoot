class CleanupStaleBulkRequestsJob < ApplicationJob
  queue_as :scheduled_jobs

  # Mark stuck bulk requests as failed based on actual job status in Sidekiq
  # A request is considered stuck if:
  # - The associated Sidekiq job doesn't exist in any queue (deleted/lost)
  # - Status is PROCESSING for more than 30 minutes
  def perform
    require 'sidekiq/api'

    cleaned_count = 0

    # Check PENDING and PROCESSING requests
    BulkProcessingRequest.where(status: %w[PENDING PROCESSING]).find_each do |request|
      next unless request.job_id.present?

      # Don't mark as failed if request was created less than 2 minutes ago
      # (give jobs time to start processing)
      next if request.created_at > 2.minutes.ago

      job_exists = check_job_exists(request.job_id)

      if !job_exists
        # Job doesn't exist in Sidekiq - mark as failed
        Rails.logger.warn("Marking bulk request #{request.id} as FAILED - job #{request.job_id} not found in Sidekiq")
        request.update!(
          status: 'FAILED',
          error_message: 'Job was lost or removed from queue. Please retry the upload.'
        )
        cleaned_count += 1
      elsif request.status == 'PROCESSING' && request.updated_at < 30.minutes.ago
        # Job exists but has been processing for too long
        Rails.logger.warn("Marking bulk request #{request.id} as FAILED - processing timeout")
        request.update!(
          status: 'FAILED',
          error_message: 'Processing timed out - job did not complete within expected time. Please retry.'
        )
        cleaned_count += 1
      end
    end

    Rails.logger.info("Cleaned up #{cleaned_count} stale bulk requests") if cleaned_count.positive?
  end

  private

  def check_job_exists(job_id)
    # Check scheduled jobs (jobs with delay)
    return true if Sidekiq::ScheduledSet.new.any? { |job| job.jid == job_id }

    # Check retry queue
    return true if Sidekiq::RetrySet.new.any? { |job| job.jid == job_id }

    # Check all regular queues
    Sidekiq::Queue.all.any? do |queue|
      queue.any? { |job| job.jid == job_id }
    end
  rescue StandardError => e
    Rails.logger.error("Error checking job existence for #{job_id}: #{e.message}")
    # If we can't check, assume it exists to avoid false positives
    true
  end
end
