# frozen_string_literal: true

class Tasks::Executors::AssignConversationExecutor
  def initialize(task)
    @task = task
  end

  def call
    data = @task.execution_config['assign_conversation_data'] || {}
    return if data['conversation_id'].blank? || data['assignee_id'].blank?

    conversation = @task.account.conversations.find_by(display_id: data['conversation_id'])
    return unless conversation

    Conversations::AssignmentService.new(
      conversation: conversation,
      assignee_id: data['assignee_id']
    ).perform
  end
end
