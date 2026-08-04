class Captain::ConversationOutcomeBoundaryJob < ApplicationJob
  queue_as :low

  # Boundary writes must not fail open: a lost boundary strands every later
  # fact in the wrong episode, and a swallowed error is never retried. Errors
  # raise here so Sidekiq retries the job; the insertion is idempotent, so a
  # retry after partial progress is safe.
  def perform(conversation, at)
    Captain::ConversationOutcomeTracker.new(conversation: conversation).record_reopen(at: at)
  end
end
