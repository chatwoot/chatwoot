class Webhooks::FacebookEventsJob < ApplicationJob
  queue_as :default
  retry_on LockAcquisitionError, wait: 15.seconds, attempts: 5

  def perform(message)
    response = ::Integrations::Facebook::MessageParser.new(message)

    lock_key = "#{response.sender_id}_#{response.recipient_id}"
    lock_manager = Redis::Lock.new

    raise LockAcquisitionError, "Failed to acquire lock for key: #{lock_key}" if lock_manager.locked?(lock_key)

    begin
      lock_manager.lock(lock_key)
      ::Integrations::Facebook::MessageCreator.new(response).perform
    ensure
      # Ensure that the lock is released even if there's an error in processing
      lock_manager.unlock(lock_key)
    end
  end
end
