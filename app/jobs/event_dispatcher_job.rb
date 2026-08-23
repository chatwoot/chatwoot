class EventDispatcherJob < ApplicationJob
  queue_as :critical

  # An event's data may reference a record (via GlobalID) that is deleted before
  # this job runs — e.g. Notification::RemoveDuplicateNotificationJob removes a
  # notification while its update event is still queued. That is a benign race,
  # not an error worth retrying, so discard cleanly instead of logging an ERROR.
  discard_on ActiveJob::DeserializationError

  def perform(event_name, timestamp, data)
    Rails.configuration.dispatcher.async_dispatcher.publish_event(event_name, timestamp, data)
  end
end
