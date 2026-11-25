# Inbox setting for who owns a conversation a person resolved when the customer's message reopens it,
# on an inbox with an active agent bot (ReopenAgentBotHandler). The default hands it to the bot; the
# other two keep it with the person, always or only while the customer answers within the window.
module InboxReopenOwner
  extend ActiveSupport::Concern

  # An int4 column; a year is far past any window a team would set and keeps the value inside it.
  MAX_WINDOW_HOURS = 8760

  included do
    enum :reopen_owner, { agent_bot: 0, assignee: 1, assignee_within_window: 2 }, prefix: true, validate: true

    validates :reopen_owner_window_hours, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_WINDOW_HOURS },
                                          allow_nil: true
    validates :reopen_owner_window_hours, presence: true, if: :reopen_owner_assignee_within_window?
  end

  # resolved_at is when the conversation was resolved, the start of the window. A conversation resolved
  # before status_changed_at was recorded has none, and goes to the bot.
  def keeps_assignee_on_reopen?(resolved_at)
    return true if reopen_owner_assignee?
    return false unless reopen_owner_assignee_within_window?

    resolved_at.present? && resolved_at >= reopen_owner_window_hours.hours.ago
  end
end
