class Captain::Copilot::ReviewJob < ApplicationJob
  include Captain::Copilot::BackgroundRunJob
  include Captain::Copilot::ConversationAccess

  queue_as :default

  RUN_KIND = 'review'.freeze
  MAX_ATTEMPTS = 2

  private

  def process_step(run, token)
    conversations = Captain::Copilot::ScreeningService.new(run, token).screen(accessible_step(run, token))
    run.with_lease(token) { run.publish_progress } if run.match.present?
    service = Captain::Copilot::ReviewService.new(run, token)
    conversations.each do |conversation|
      run.renew_lease(token)
      review(run, token, service, conversation)
    end
    run.with_lease(token) { run.publish_progress } if conversations.any?
    # A review stops at its budget; continue_review raises it when the agent asks for the next batch.
    return finalize(run, token) if run.budget_left <= 0

    continue_or_finalize(run, token)
  end

  def accessible_step(run, token)
    ids = run.remaining_ids.first([STEP_SIZE, run.budget_left].min)
    conversations = accessible_conversations(account: run.account, user: run.user).where(id: ids).to_a
    run.with_lease(token) { (ids - conversations.map(&:id)).each { |id| record_error(run, id, 'Conversation is no longer accessible') } }
    conversations
  end

  def review(run, token, service, conversation)
    deep = run.findings.exists?(conversation_id: conversation.id, status: 'more_history')
    attributes = service.analyze(conversation, deep: deep)
    attributes = attributes.merge(status: 'error', error: 'The last 50 messages were insufficient') if attributes[:status] == 'more_history' && deep
    run.with_lease(token) { save_result(run, conversation.id, attributes) }
  rescue Captain::Copilot::LeaseLostError, Captain::Copilot::LimitExceededError
    raise
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: run.account).capture_exception
    error = e.is_a?(ArgumentError) ? e.message : "Analysis failed (#{e.class.name})"
    run.with_lease(token) { record_error(run, conversation.id, error) }
  end

  def save_result(run, id, attributes)
    finding = run.findings.find_or_initialize_by(conversation_id: id)
    return if finding.status == 'resolved'

    finding.update!(error: nil, **attributes, attempts: finding.attempts + 1)
  end

  def record_error(run, id, error)
    finding = run.findings.find_or_initialize_by(conversation_id: id)
    return if finding.status == 'resolved'

    attempts = finding.attempts + 1
    finding.update!(status: attempts >= MAX_ATTEMPTS ? 'error' : 'retry', error: error, attempts: attempts)
  end

  def incomplete?(run)
    run.findings.exists?(status: 'error') || run.context['selection_truncated']
  end
end
