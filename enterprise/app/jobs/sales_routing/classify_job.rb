class SalesRouting::ClassifyJob < ApplicationJob
  queue_as :default

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation && SalesRouting::Configuration.new(inbox: conversation.inbox).enabled?

    ready = conversation.with_lock { SalesRouting::Classifier.new(conversation: conversation).perform }
    AutoAssignment::AssignmentJob.enqueue_for_inbox(conversation.inbox_id) if ready && conversation.open? && conversation.assignee_id.nil?
  end
end
