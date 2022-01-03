class Conversations::ResolutionJob < ApplicationJob
  queue_as :medium

  def perform(account:)
    resolvable_conversations = account.conversations.resolvable(account.auto_resolve_duration)
    resolvable_conversations.each(&:toggle_status)
  end
end
