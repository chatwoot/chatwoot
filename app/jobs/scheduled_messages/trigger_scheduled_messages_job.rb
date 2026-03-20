class ScheduledMessages::TriggerScheduledMessagesJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    ScheduledMessage.due_for_sending.find_each(batch_size: 100) do |scheduled_message|
      ScheduledMessages::SendScheduledMessageJob.perform_later(scheduled_message.id)
    end
  end
end
