class TriggerAutomationEventsJob < ApplicationJob
  include Events::Types

  queue_as :scheduled_jobs

  def perform
    Conversation.where(status: :open).all.each do |conversation|
      return false if conversation.last_incoming_message.nil?

      Rails.configuration.dispatcher.dispatch(MESSAGE_HOURS_SINCE_LAST, Time.zone.now, message: conversation.last_incoming_message)
    end
  end
end
