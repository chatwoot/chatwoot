class DelayDispatchEventJob < ApplicationJob
  queue_as :high

  def perform(event_name:, timestamp:, message_id:, performed_by_id: nil, previous_changes: nil)
    message = Message.find_by(id: message_id)
    return unless message

    data = {
      message: message
    }

    if performed_by_id
      performed_by = User.find_by(id: performed_by_id)
      data[:performed_by] = performed_by if performed_by
    end

    data[:previous_changes] = previous_changes if previous_changes

    Rails.configuration.dispatcher.dispatch(event_name, timestamp, data)
  end
end
