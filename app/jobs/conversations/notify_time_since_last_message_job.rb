class Conversations::NotifyTimeSinceLastMessageJob < ApplicationJob
  include Events::Types

  queue_as :scheduled_jobs

  def perform
    Conversation.where(status: :open).all.each do |conversation|
      return false if conversation.last_incoming_message.nil?

      Rails.configuration.dispatcher.dispatch(TIME_SINCE_LAST_MESSAGE,
                                              Time.zone.now,
                                              conversation: conversation,
                                              time_since_last_message: (Time.current - conversation.last_incoming_message.created_at),
                                              performed_by: Current.executed_by)
    end
  end
end
