class Webhooks::FacebookEventsJob < ApplicationJob
  queue_as :default
  retry_on LockAcquisitionError, wait: 2.seconds, attempts: 5

  def perform(message)
    response = ::Integrations::Facebook::MessageParser.new(message)

    with_lock(::Redis::Alfred::FACEBOOK_MESSAGE_MUTEX, sender_id: response.sender_id, recipient_id: response.recipient_id) do
      ::Integrations::Facebook::MessageCreator.new(response).perform
    end
  end
end
