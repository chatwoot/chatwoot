class KanbanScheduleTriggerJob < ApplicationJob
  queue_as :default

  def perform(schedule_id)
    schedule = KanbanCardSchedule.pending.find_by(id: schedule_id)
    return unless schedule

    card = schedule.kanban_card
    open_conversation = card.contact.conversations.open.order(created_at: :desc).first

    if open_conversation.nil?
      schedule.cancelled!
      return
    end

    schedule.triggered!
    create_notification(schedule, card, open_conversation)
  rescue StandardError => e
    Rails.logger.error("KanbanScheduleTriggerJob failed for schedule #{schedule_id}: #{e.message}")
  end

  private

  def create_notification(schedule, card, conversation)
    Notification.create!(
      account: card.kanban_board.account,
      user: schedule.created_by,
      notification_type: :kanban_reminder,
      primary_actor: conversation,
      meta: {
        title: schedule.title,
        description: schedule.description,
        card_id: card.id,
        contact_name: card.contact.name
      }
    )
  end
end
