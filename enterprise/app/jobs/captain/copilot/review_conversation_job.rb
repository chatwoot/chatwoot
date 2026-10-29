# Reviews one conversation of a review's batch. Captain::Copilot::ReviewJob queues one of these per conversation, so
# Sidekiq reviews them side by side, and the last one to finish queues ReviewJob again for the next batch.
class Captain::Copilot::ReviewConversationJob < ApplicationJob
  include Captain::Copilot::ConversationAccess

  queue_as :low

  def perform(run_id, conversation_id)
    run = CopilotRun::Review.find_by(id: run_id)
    # A repeated job, or one for a batch recovery took back, has nothing to do.
    return unless run&.pending?(conversation_id)

    result = review(run, conversation_id)
    last = run.finish_pending(conversation_id) do
      run.record_failure(conversation_id, result[:error]) if result[:error]
      run.save_finding(conversation_id, result[:finding]) if result[:finding]
    end
    Captain::Copilot::ReviewJob.perform_later(run.id) if last
  end

  private

  # A failed review is recorded on its conversation, so the rest of the batch goes on. Running out of credits or the
  # review being switched off leaves the conversation for ReviewJob, which ends the review on its next batch.
  def review(run, conversation_id)
    # Access is checked again, because the job may wait in the queue after ReviewJob checked it.
    conversation = accessible_conversations(account: run.account, user: run.user).find_by(id: conversation_id)
    return { error: 'Conversation is no longer accessible' } unless conversation

    deep = run.findings.needs_more_history.exists?(conversation_id: conversation_id)
    finding = Captain::Copilot::ReviewService.new(run).review(conversation, deep: deep)
    return { finding: finding } unless finding[:status] == :needs_more_history && deep

    { finding: finding.merge(status: :failed, error: 'The 50 messages read were insufficient') }
  rescue Captain::Copilot::LimitExceededError
    {}
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: run.account).capture_exception
    { error: e.is_a?(ArgumentError) ? e.message : "Review failed (#{e.class.name})" }
  end
end
