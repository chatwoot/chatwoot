class Copilot::V2::Runner # rubocop:disable Metrics/ClassLength
  class StaleClaim < StandardError; end
  class BudgetExceeded < StandardError; end
  class Paused < StandardError; end

  attr_reader :run, :resources, :generation

  def initialize(run)
    @run = run
    @resources = Copilot::V2::Resources.new(account: run.account, user: run.user, assistant: run.copilot_thread.assistant)
  end

  def call # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    @generation = run.claim!
    return unless generation

    authorize!
    prepare_history if run.checkpoint.fetch('transcript', []).empty?
    pending = run.checkpoint.fetch('operations', []).find { |operation| operation['state'] == 'pending' }
    if pending
      Copilot::V2::Operations.new(self).perform(pending)
    else
      coordinate
    end
    requeue
  rescue StaleClaim
    nil
  rescue Paused, BudgetExceeded => e
    pause(e.message)
  rescue Pundit::NotAuthorizedError, ActiveRecord::RecordNotFound
    pause('access_unavailable')
  rescue StandardError => e
    Rails.logger.warn("Copilot V2 run #{run.id} failed: #{e.class}")
    pause('execution_error')
  end

  def authorize!
    account = run.account.reload
    raise Paused, 'feature_disabled' unless account.feature_enabled?('copilot_v2')
    raise Pundit::NotAuthorizedError unless account.active? && account.account_users.exists?(user_id: run.user.id)
    raise Pundit::NotAuthorizedError unless run.copilot_thread.v2?
    return unless run.charged_at.nil? && !account.usage_limits.dig(:captain, :responses, :current_available).to_i.positive?

    raise Paused, 'response_credits_unavailable'
  end

  def commit!
    run.account.with_lock do
      run.fenced!(generation) do
        authorize!
        yield
      end
    end
  end

  def provider_call(input, &) # rubocop:disable Metrics/AbcSize
    bytes = input.to_json.bytesize + Copilot::V2::Limits::STATIC_PROMPT_BYTES
    reserve!(bytes)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response = Timeout.timeout(Copilot::V2::Limits::MODEL_TIMEOUT, &)
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    commit! do
      usage = run.budget.deep_dup
      usage['reserved_model_seconds'] -= [Copilot::V2::Limits::MODEL_TIMEOUT - elapsed, 0].max
      usage['input_tokens'] = usage.fetch('input_tokens', 0) + response.input_tokens.to_i
      usage['output_tokens'] = usage.fetch('output_tokens', 0) + response.output_tokens.to_i
      usage['completed_provider_responses'] = usage.fetch('completed_provider_responses', 0) + 1
      run.update!(budget: usage)
    end
    response
  end

  def client
    @client ||= Copilot::V2::ChatService.new(account: run.account, user: run.user, thread: run.copilot_thread,
                                             assistant: run.copilot_thread.assistant)
  end

  def finish_operation(operation, result)
    commit! do
      checkpoint = run.checkpoint.deep_dup
      stored = checkpoint.fetch('operations').find { |entry| entry['id'] == operation.fetch('id') }
      stored['state'] = 'done'
      stored['result'] = result
      checkpoint['transcript'] << { 'role' => 'tool', 'tool_call_id' => operation.fetch('id'), 'content' => result.to_json }
      run.update!(checkpoint: checkpoint)
    end
  end

  def manifest(key)
    value = run.datasets.fetch(key).deep_dup
    items = run.copilot_run_items.where(dataset_key: key).order(:position)
    value['rows'] = items.map(&:captured) if value['reference_type'] == 'selection'
    value['items'] = items.map(&:captured) if value['reference_type'] == 'evidence'
    value
  end

  private

  def reserve!(bytes) # rubocop:disable Metrics/AbcSize
    limits = Copilot::V2::Limits
    commit! do
      usage = run.budget.deep_dup
      raise BudgetExceeded, 'request_too_large' if bytes > limits::REQUEST_BYTES
      raise BudgetExceeded, 'model_call_budget' if usage.fetch('logical_model_calls', 0) >= limits::MODEL_CALLS
      raise BudgetExceeded, 'model_time_budget' if usage.fetch('reserved_model_seconds', 0) + limits::MODEL_TIMEOUT > limits::MODEL_SECONDS
      raise BudgetExceeded, 'input_budget' if usage.fetch('estimated_input_bytes', 0) + bytes > limits::INPUT_BYTES

      usage['logical_model_calls'] = usage.fetch('logical_model_calls', 0) + 1
      usage['reserved_model_seconds'] = usage.fetch('reserved_model_seconds', 0) + limits::MODEL_TIMEOUT
      usage['estimated_input_bytes'] = usage.fetch('estimated_input_bytes', 0) + bytes
      usage['usage_note'] = 'Logical calls include failed/lost attempts. SDK transport retries may issue additional requests. ' \
                            'Reserved time includes full timeout for lost calls; reported tokens include only received usage. ' \
                            'Input bytes include dynamic request/schema plus conservative estimated static overhead, not exact wire bytes.'
      run.update!(budget: usage)
    end
  end

  def prepare_history # rubocop:disable Metrics/AbcSize
    history = run.copilot_thread.copilot_messages.where(id: ..run.triggering_message_id, message_type: %w[user assistant]).order(:id)
                 .map { |message| { 'role' => message.message_type, 'content' => message.message.fetch('content') } }
    previous = run.copilot_thread.copilot_runs.where.not(id: run.id).order(id: :desc).limit(20)
    references = previous.each_with_object({}) do |old, values|
      values.merge!(old.datasets.transform_values do |value|
        value.except('rows', 'items')
      end)
    end
    commit! { run.update!(checkpoint: run.checkpoint.merge('transcript' => history, 'reference_context' => references)) }
  end

  def coordinate # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    operations = Copilot::V2::Operations.new(self)
    operations.refresh_visible_results!
    response = provider_call(run.checkpoint.slice('transcript', 'reference_context').merge('tools' => Copilot::V2::Tool::CONTRACTS)) do
      client.coordinate(run)
    end
    entry = Copilot::V2::ChatService.serialize(response)
    if entry.fetch('tool_calls').any?
      save_tool_calls(entry)
    else
      content = response.content.is_a?(Hash) ? response.content : JSON.parse(response.content)
      if operations.refresh_visible_results!
        content = { 'status' => 'completed',
                    'answer' => 'Some records are no longer available. See the saved partial results and unresolved records.' }
        entry['content'] = content.to_json
      end
      finalize(content, entry)
    end
  rescue JSON::ParserError, ArgumentError, RubyLLM::Error, Timeout::Error => e
    commit! do
      usage = run.budget.merge('coordinator_failures' => run.budget.fetch('coordinator_failures', 0) + 1)
      run.update!(budget: usage)
    end
    raise BudgetExceeded, 'coordinator_retry_budget' if run.budget['coordinator_failures'] >= Copilot::V2::Limits::COORDINATOR_FAILURES

    Rails.logger.info("Copilot V2 coordinator retry: #{e.class}")
  end

  def save_tool_calls(entry)
    commit! do
      checkpoint = run.checkpoint.deep_dup
      operations = checkpoint.fetch('operations')
      calls = entry.fetch('tool_calls')
      ids = operations.pluck('id') + calls.pluck('id')
      raise ArgumentError, 'Duplicate tool call IDs' unless ids.uniq == ids
      raise BudgetExceeded, 'operation_budget' if ids.size > Copilot::V2::Limits::OPERATIONS

      checkpoint['transcript'] << entry
      checkpoint['operations'] += calls.map { |call| call.merge('state' => 'pending') }
      run.update!(checkpoint: checkpoint)
    end
  end

  def finalize(content, entry) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    raise ArgumentError, 'Invalid coordinator response' unless content.keys.sort == %w[answer status] && content['answer'].is_a?(String) &&
                                                               %w[completed needs_clarification].include?(content['status'])

    clarification = content['status'] == 'needs_clarification'
    summaries = Array(run.checkpoint['published_refs']).map do |key|
      saved = run.checkpoint.fetch('published_results', {}).fetch(key, {})
      Copilot::V2::Results.new(run).projection(key).merge('reference' => key, 'freshness' => saved['freshness'])
    end
    complete = summaries.all? do |summary|
      summary['selection_complete'] != false && summary['processing_complete'] != false &&
        summary.dig('selection', 'complete') != false
    end
    complete = false if summaries.empty? && run.datasets.any?
    commit! do
      checkpoint = run.checkpoint.deep_dup
      checkpoint['transcript'] << entry
      answer = run.copilot_thread.copilot_messages.create!(message_type: :assistant, copilot_run: run, message: { 'content' => content['answer'] })
      unless clarification || run.charged_at
        run.account.increment_response_usage
        run.charged_at = Time.current
      end
      run.update!(status: if clarification
                            'needs_clarification'
                          else
                            (complete ? 'completed' : 'incomplete')
                          end,
                  reason: complete || clarification ? nil : 'partial_results', response_message: answer,
                  result_summary: { 'answer' => content['answer'], 'question' => clarification ? content['answer'] : nil, 'results' => summaries },
                  checkpoint: checkpoint, lease_expires_at: nil, completed_at: clarification ? nil : Time.current)
    end
  end

  def requeue
    return unless run.reload.status == 'running'

    commit! { run.update!(status: 'queued', lease_expires_at: nil) }
    Copilot::V2::RunJob.perform_later(run.id)
  end

  def pause(reason)
    return unless generation

    run.fenced!(generation) do
      summary = Copilot::V2::Results.new(run).saved_summary(reason: reason)
      answer = run.response_message || run.copilot_thread.copilot_messages.create!(
        message_type: :assistant, copilot_run: run,
        message: { 'content' => 'This run is incomplete. Saved findings and unresolved records are available with the run.' }
      )
      summary['answer'] = answer.message.fetch('content')
      run.update!(status: 'incomplete', reason: reason, lease_expires_at: nil, result_summary: summary, response_message: answer)
    end
  rescue StaleClaim
    nil
  end
end
