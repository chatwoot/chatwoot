class Captain::Copilot::ReviewJob < ApplicationJob
  include Captain::Copilot::BackgroundRunJob
  include Captain::Copilot::ConversationAccess

  # Screening makes up to 25 model calls in a row, so it runs on low with Captain's other long jobs instead of holding the
  # workers that handle incoming messages.
  queue_as :low

  RUN_CLASS = CopilotRun::Review

  private

  # Screens a batch, then hands each conversation that passed to a Captain::Copilot::ReviewConversationJob, so Sidekiq
  # reviews them side by side. The last of those jobs queues this one again for the next batch. The card shows up before
  # screening, which is the longest wait here.
  def process_batch(run, token)
    # Checked before each batch, so a review that runs out of credits or is switched off ends instead of looping.
    run.ensure_can_continue!
    # A review stops at its turn limit; continue_review raises it when the agent asks for the next batch.
    return finalize(run, token) if run.left_this_turn <= 0 || run.remaining_ids.empty?

    run.with_lease(token) { run.publish_progress }
    conversations = Captain::Copilot::ScreeningService.new(run, token).screen(accessible_batch(run, token))
    run.with_lease(token) { run.publish_progress }
    return continue_or_finalize(run, token) if conversations.empty?

    start_reviews(run, token, conversations.map(&:id))
  end

  def accessible_batch(run, token)
    ids = run.remaining_ids.first([BATCH_SIZE, run.left_this_turn].min)
    found = accessible_conversations(account: run.account, user: run.user).where(id: ids).index_by(&:id)
    run.with_lease(token) { (ids - found.keys).each { |id| run.record_failure(id, 'Conversation is no longer accessible') } }
    # In the saved order, newest first, so a run that stops partway has reviewed the newest conversations.
    ids.filter_map { |id| found[id] }
  end

  # The run is released before the jobs are queued, so the first one to finish finds it reviewing.
  def start_reviews(run, token, conversation_ids)
    run.with_lease(token) do
      run.update!(pending_ids: conversation_ids)
      run.release!(:reviewing)
    end
    conversation_ids.each { |conversation_id| Captain::Copilot::ReviewConversationJob.perform_later(run.id, conversation_id) }
  end

  def incomplete?(run)
    run.findings.failed.exists? || run.selection_truncated?
  end
end
