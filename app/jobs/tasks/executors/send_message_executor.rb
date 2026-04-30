# frozen_string_literal: true

class Tasks::Executors::SendMessageExecutor
  def initialize(task)
    @task = task
  end

  def call
    return unless @task.entity_type == 'Conversation'

    conversation = @task.account.conversations.find_by(display_id: @task.entity_id)
    return unless conversation

    message_content = @task.execution_config['message_content'].presence
    return unless message_content

    Messages::MessageBuilder.new(sender, conversation, message_params(message_content)).perform
  end

  private

  def sender
    @task.assignee || @task.account.users.with_role(:administrator).first
  end

  def message_params(content)
    {
      content: content,
      message_type: :outgoing,
      content_type: :text
    }
  end
end
