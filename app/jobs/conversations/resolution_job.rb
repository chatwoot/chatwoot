class Conversations::ResolutionJob < ApplicationJob
  queue_as :medium

  def perform(account:)
    resolvable_conversations = account.conversations.open.select(&:auto_resolve?)
    resolvable_conversations.each(&:toggle_status)
  end
end
