class Captain::Copilot::ActionJob < ApplicationJob
  include Captain::Copilot::BackgroundRunJob

  queue_as :default

  RUN_KIND = :action
  MAX_ATTEMPTS = 2

  private

  # Current.user makes activity messages, such as "added the label", name the agent who approved the change.
  def process_batch(run, token)
    run.ensure_can_continue!(credits: false)
    Current.user = run.user
    action = run.action
    resource = Captain::Copilot::Resources.build(action.class::RESOURCE, account: run.account, user: run.user)
    run.remaining_ids.first(BATCH_SIZE).each do |id|
      run.renew_lease(token)
      # Loaded through the access scope right before the change, so access lost partway through a batch stops it.
      apply(run, token, action, id, resource.scope.find_by(id: id))
    end
    run.with_lease(token) { run.publish_progress }
    continue_or_finalize(run, token)
  ensure
    Current.reset
  end

  def apply(run, token, action, id, record)
    status = record ? action.perform(record) : :failed
    run.with_lease(token) { save_item(run, id, status, record ? nil : 'Record is no longer accessible') }
  rescue Captain::Copilot::LeaseLostError
    raise
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: run.account).capture_exception
    run.with_lease(token) { save_item(run, id, :awaiting_retry, "Change failed (#{e.class.name})") }
  end

  def save_item(run, id, status, error)
    item = run.action_items.find_or_initialize_by(record_id: id)
    attempts = item.attempts + 1
    status = :failed if status == :awaiting_retry && attempts >= MAX_ATTEMPTS
    item.update!(status: status, error: error, attempts: attempts)
  end

  def incomplete?(run)
    run.action_items.failed.exists?
  end
end
