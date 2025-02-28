class Conversations::TimerAutomationRulesJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Conversation.open.find_each(batch_size: 100) do |conversation|
      Rails.configuration.dispatcher.dispatch('waiting', Time.current, conversation: conversation)
    end
  end
end
