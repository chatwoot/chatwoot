class CleanupStaleBulkRequestsJob < ApplicationJob
  queue_as :scheduled_jobs

  # Mark stuck bulk requests as failed
  # A request is considered stuck if:
  # - Status is PENDING for more than 5 minutes
  # - Status is PROCESSING for more than 30 minutes
  def perform
    timeout_pending = 5.minutes.ago
    timeout_processing = 30.minutes.ago

    # Find PENDING requests older than 5 minutes
    stale_pending = BulkProcessingRequest.where(status: 'PENDING')
                                         .where('created_at < ?', timeout_pending)

    stale_pending.find_each do |request|
      Rails.logger.warn("Marking stuck PENDING bulk request #{request.id} as FAILED")
      request.update!(
        status: 'FAILED',
        error_message: 'Request timed out - job was not processed within expected time. Please retry.'
      )
    end

    # Find PROCESSING requests older than 30 minutes
    stale_processing = BulkProcessingRequest.where(status: 'PROCESSING')
                                            .where('updated_at < ?', timeout_processing)

    stale_processing.find_each do |request|
      Rails.logger.warn("Marking stuck PROCESSING bulk request #{request.id} as FAILED")
      request.update!(
        status: 'FAILED',
        error_message: 'Processing timed out - job did not complete within expected time. Please retry.'
      )
    end

    total_cleaned = stale_pending.count + stale_processing.count
    Rails.logger.info("Cleaned up #{total_cleaned} stale bulk requests") if total_cleaned.positive?
  end
end
