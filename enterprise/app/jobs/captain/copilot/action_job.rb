class Captain::Copilot::ActionJob < ApplicationJob
  include Captain::Copilot::BackgroundRunJob
  include Captain::Copilot::ConversationAccess

  queue_as :default

  RUN_KIND = 'action'.freeze
  MAX_ATTEMPTS = 2

  private

  # Current.user makes activity messages, such as "added the label", name the agent who approved the change.
  def process_step(run, token)
    Current.user = run.user
    action = run.action
    ids = run.remaining_ids.first(STEP_SIZE)
    conversations = accessible_conversations(account: run.account, user: run.user).where(id: ids).index_by(&:id)
    ids.each do |id|
      run.renew_lease(token)
      apply(run, token, action, id, conversations[id])
    end
    run.with_lease(token) { run.publish_progress }
    continue_or_finalize(run, token)
  ensure
    Current.reset
  end

  def apply(run, token, action, id, conversation)
    status = conversation ? action.perform(conversation) : 'failed'
    run.with_lease(token) { save_item(run, id, status, conversation ? nil : 'Conversation is no longer accessible') }
  rescue Captain::Copilot::LeaseLostError
    raise
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: run.account).capture_exception
    run.with_lease(token) { save_item(run, id, 'retry', "Change failed (#{e.class.name})") }
  end

  def save_item(run, id, status, error)
    item = run.action_items.find_or_initialize_by(record_id: id)
    attempts = item.attempts + 1
    status = 'failed' if status == 'retry' && attempts >= MAX_ATTEMPTS
    item.update!(status: status, error: error, attempts: attempts)
  end

  def incomplete?(run)
    run.action_items.exists?(status: 'failed')
  end
end
