class Conversations::TimelineBuilder
  pattr_initialize [:conversation!, :user!]

  def perform
    (message_items + task_event_items).sort_by { |item| item[:occurred_at] }
  end

  private

  def message_items
    conversation.messages
                .where(account_id: conversation.account_id)
                .includes(:sender, :attachments)
                .find_each
                .map do |message|
      next if message.private? && !Conversations::PrivateNoteVisibility.allowed?(
        user: user, message: message, conversation: conversation
      )

      {
        type: 'message',
        id: message.id,
        occurred_at: message.created_at,
        payload: message.push_event_data
      }
    end.compact
  end

  def task_event_items
    InternalTaskEvent.joins(:internal_task)
                     .where(internal_task_id: visible_task_ids)
                     .includes(:user, internal_task: :task_template)
                     .find_each
                     .map do |event|
      {
        type: 'task_event',
        id: event.id,
        occurred_at: event.created_at,
        payload: {
          event_type: event.event_type,
          metadata: event.metadata,
          task: {
            id: event.internal_task_id,
            title: event.internal_task.title,
            status: event.internal_task.status
          },
          user: event.user&.push_event_data
        }
      }
    end
  end

  def visible_task_ids
    account_user = conversation.account.account_users.find_by(user_id: user.id)
    InternalTaskPolicy::Scope.new(
      { user: user, account: conversation.account, account_user: account_user },
      InternalTask
    ).resolve.where(conversation_id: conversation.id).select(:id)
  end
end
