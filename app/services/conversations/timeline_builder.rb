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
      next if message.private? && !can_view_private_notes?(message)

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
                     .where(internal_tasks: { conversation_id: conversation.id })
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

  # Returns true when the user is allowed to read a given private note on this
  # conversation. Conservative rules — replace with a dedicated NotePolicy when
  # one exists in the codebase:
  # - conversation administrators see every note
  # - the note's author always sees their own note
  # - the conversation assignee and team members see notes for context
  def can_view_private_notes?(message)
    return false if user.blank?
    return false if message.account_id != conversation.account_id

    account_user = conversation.account.account_users.find_by(user_id: user.id)
    return true if account_user&.administrator?

    return true if message.sender_id == user.id

    assigned = conversation.assignee_id == user.id
    on_team = conversation.team_id.present? && user.teams.exists?(id: conversation.team_id)
    assigned || on_team
  end
end
