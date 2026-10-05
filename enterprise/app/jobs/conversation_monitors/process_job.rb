class ConversationMonitors::ProcessJob < ApplicationJob
  queue_as :monitors_live

  def perform(conversation_id)
    work = ConversationMonitors::WorkItem.find_by(conversation_id: conversation_id)
    return unless work

    ConversationMonitors::Evaluator.new(work).perform
  rescue ActiveRecord::RecordNotFound
    # Source deletion cascades to durable work and evaluations.
    nil
  end
end
