class DelayDispatchEventJob < ApplicationJob
  queue_as :high

  def perform(event_name:, timestamp:, message_id:)
    message = Message.find_by(id: message_id)
    return unless message

    data = {
      message: message
    }
    Rails.configuration.dispatcher.dispatch(event_name, timestamp, data)
  end
end
