# Locks tickets whose conversation has stayed resolved long enough that a follow
# up belongs on a new ticket rather than on this one. Once closed_at is set,
# Conversation#validate_ticket_not_closed refuses to reopen the conversation.
class Tickets::CloseResolvedJob < ApplicationJob
  queue_as :scheduled_jobs

  CLOSE_AFTER = 7.days

  def perform
    Ticket.joins(:conversation)
          .where(closed_at: nil)
          .where(conversations: { status: Conversation.statuses[:resolved] })
          .where(conversations: { status_changed_at: ...CLOSE_AFTER.ago })
          .find_each { |ticket| ticket.update!(closed_at: Time.current) }
  end
end
