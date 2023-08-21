class SendOnSlackJob < ApplicationJob
  class LockAcquisitionError < StandardError; end

  queue_as :medium
  retry_on LockAcquisitionError, wait: 3.seconds, attempts: 5

  def perform(message, hook)
    lock_key = format(::Redis::Alfred::SLACK_MESSAGE_MUTEX, sender_id: message.sender_id, reference_id: hook.reference_id)
    lock_manager = Redis::LockManager.new

    if lock_manager.locked?(lock_key)
      Rails.logger.error "[SendOnSlackJob] Failed to acquire lock on attempt #{executions + 1}: #{lock_key}"
      raise LockAcquisitionError, "Failed to acquire lock for key: #{lock_key}"
    end

    begin
      Rails.logger.info "[SendOnSlackJob] Acquired lock for: #{lock_key}"
      Integrations::Slack::SendOnSlackService.new(message: message, hook: hook).perform
    ensure
      # Ensure that the lock is released even if there's an error in processing
      lock_manager.unlock(lock_key)
    end
  end
end
