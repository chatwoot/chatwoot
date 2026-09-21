class Copilot::V2::RunService
  class ActiveRunConflict < StandardError; end
  class Unavailable < StandardError; end

  def initialize(thread:, user:)
    @thread = thread
    @user = user
  end

  def start(message:)
    authorize!
    raise ArgumentError, 'An owner user message is required' unless message.copilot_thread_id == @thread.id && message.user?

    run = @thread.with_lock do
      message.reload
      next message.copilot_run if message.copilot_run

      current = @thread.copilot_runs.active.first
      if current&.status == 'needs_clarification'
        resolve_clarification(current, message)
      else
        raise ActiveRunConflict, 'A run is already active in this thread' if current

        @thread.copilot_runs.create!(triggering_message: message, task_spec: { 'version' => 1, 'request' => message.message.fetch('content') },
                                     checkpoint: { 'history_through_id' => message.id, 'transcript' => [], 'operations' => [] }).tap do |created|
          message.update!(copilot_run: created)
        end
      end
    end
    enqueue(run)
    run
  end

  def resume(run:)
    authorize!
    own_run!(run)
    @thread.with_lock do
      run.reload
      raise ActiveRunConflict, 'A run is already active in this thread' if @thread.copilot_runs.active.where.not(id: run.id).exists?
      raise ArgumentError, 'Only incomplete runs can resume' unless run.status == 'incomplete'

      run.update!(status: 'queued', reason: nil, lease_expires_at: nil)
    end
    enqueue(run)
    run
  end

  def cancel(run:)
    authorize!(execution: false)
    own_run!(run)
    run.with_lock do
      unless %w[completed failed cancelled].include?(run.status)
        run.update!(status: 'cancelled', reason: 'user_cancelled', claim_generation: run.claim_generation + 1, lease_expires_at: nil,
                    result_summary: Copilot::V2::Results.new(run).saved_summary(reason: 'user_cancelled'))
      end
    end
    run
  end

  private

  def own_run!(run)
    raise ActiveRecord::RecordNotFound unless run.copilot_thread_id == @thread.id
  end

  def authorize!(execution: true)
    raise Pundit::NotAuthorizedError unless @thread.user_id == @user.id && @thread.account.account_users.exists?(user_id: @user.id)
    raise Unavailable, 'New-engine thread required' unless @thread.v2?
    return unless execution

    account = @thread.account.reload
    raise Unavailable, 'Account is inactive' unless account.active?
    raise Unavailable, 'Copilot V2 is disabled' unless account.feature_enabled?('copilot_v2')
  end

  def resolve_clarification(run, message)
    checkpoint = run.checkpoint.deep_dup
    checkpoint['transcript'] << { 'role' => 'user', 'content' => message.message.fetch('content') }
    checkpoint['history_through_id'] = message.id
    run.update!(status: 'queued', reason: nil, checkpoint: checkpoint, response_message: nil,
                task_spec: run.task_spec.merge('clarifications' => Array(run.task_spec['clarifications']) + [message.message.fetch('content')]))
    message.update!(copilot_run: run)
    run
  end

  def enqueue(run)
    Copilot::V2::RunJob.perform_later(run.id) if run.status == 'queued'
  end
end
