class Webhooks::FacebookEventsJob < ApplicationJob
  class LockAcquisitionError < StandardError; end

  queue_as :default
  # https://edgeapi.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html#method-i-retry_on
  retry_on LockAcquisitionError, wait: 1.second, attempts: 6

  def perform(message)
    response = ::Integrations::Facebook::MessageParser.new(message)

    lock_key = format(::Redis::Alfred::FACEBOOK_MESSAGE_MUTEX, sender_id: response.sender_id, recipient_id: response.recipient_id)
    lock_manager = Redis::LockManager.new

    if lock_manager.locked?(lock_key)
      Rails.logger.error "[Facebook::MessageCreator] Failed to acquire lock on attempt #{executions}: #{lock_key}"
      raise LockAcquisitionError, "Failed to acquire lock for key: #{lock_key}"
    end

    begin
      lock_manager.lock(lock_key)
      Rails.logger.info "[Facebook::MessageCreator] Acquired lock for: #{lock_key}"
      ::Integrations::Facebook::MessageCreator.new(response).perform
    ensure
      # Ensure that the lock is released even if there's an error in processing
      lock_manager.unlock(lock_key)
    end
  end
end
