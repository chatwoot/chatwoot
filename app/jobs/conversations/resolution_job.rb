class Conversations::ResolutionJob < ApplicationJob
  queue_as :low

  def perform(account:)
    # limiting the number of conversations to be resolved to avoid any performance issues
    resolvable_conversations = account.conversations.resolvable(account.auto_resolve_duration).limit(Limits::BULK_ACTIONS_LIMIT)
    resolvable_conversations.each(&:toggle_status)
  end
end
