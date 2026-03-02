class Internal::BackfillConversationCountersService
  # Backfills the conversation status counter cache columns on accounts
  # (open_conversations_count, resolved_conversations_count, pending_conversations_count, snoozed_conversations_count).
  #
  # Safe to re-run to correct any drift.
  #
  # Usage:
  #   Internal::BackfillConversationCountersService.new.perform
  #   Internal::BackfillConversationCountersService.new(account: Account.find(id)).perform
  #
  def initialize(account: nil)
    @account = account
  end

  def perform
    scope = @account ? Account.where(id: @account.id) : Account.all
    scope.find_each do |account|
      account.update(
        open_conversations_count: account.conversations.open.count,
        resolved_conversations_count: account.conversations.resolved.count,
        pending_conversations_count: account.conversations.pending.count,
        snoozed_conversations_count: account.conversations.snoozed.count
      )
    end
  end
end
