class CloudflareCleanupJob < ApplicationJob
  queue_as :housekeeping

  def perform
    Rails.logger.info 'CloudflareCleanupJob: No cleanup needed (Community Edition)'
  end
end

CloudflareCleanupJob.prepend_mod_with('CloudflareCleanupJob')
