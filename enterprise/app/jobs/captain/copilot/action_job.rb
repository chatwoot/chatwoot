class Captain::Copilot::ActionJob < ApplicationJob
  include Captain::Copilot::BackgroundRunJob

  queue_as :default

  RUN_KIND = :action
  MAX_ATTEMPTS = 2
  INTERRUPTED = 'Stopped while the change was being made. It may have been made, so it was not tried again.'.freeze

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

  # A change that is not safe to repeat is marked applying before it runs. If the worker dies before the outcome is saved,
  # the next attempt finds the marker and fails the record instead of making the change twice.
  def apply(run, token, action, id, record)
    raise Captain::Copilot::ActionNotApplicableError, 'Record is no longer accessible' unless record
    raise Captain::Copilot::ActionNotApplicableError, INTERRUPTED if run.action_items.applying.exists?(record_id: id)

    save_item(run, token, id, :applying) unless action.class::REPEATABLE
    save_item(run, token, id, action.perform(record))
  rescue Captain::Copilot::ActionNotApplicableError => e
    save_item(run, token, id, :failed, e.message)
  rescue Captain::Copilot::LeaseLostError
    raise
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: run.account).capture_exception
    save_item(run, token, id, action.class::REPEATABLE ? :awaiting_retry : :failed, "Change failed (#{e.class.name})")
  end

  # Finishing an applying record completes the same attempt.
  def save_item(run, token, id, status, error = nil)
    run.with_lease(token) do
      item = run.action_items.find_or_initialize_by(record_id: id)
      attempts = item.applying? ? item.attempts : item.attempts + 1
      status = :failed if status == :awaiting_retry && attempts >= MAX_ATTEMPTS
      item.update!(status: status, error: error&.truncate(ApplicationRecord::MAX_STRING_COLUMN_LENGTH), attempts: attempts)
    end
  end

  def incomplete?(run)
    run.action_items.failed.exists?
  end
end
