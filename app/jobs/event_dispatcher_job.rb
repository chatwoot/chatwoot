class EventDispatcherJob < ApplicationJob
  queue_as :events

  def perform(event_name, timestamp, data)
    Rails.configuration.dispatcher.async_dispatcher.publish_event(event_name, timestamp, data)
  end
end
