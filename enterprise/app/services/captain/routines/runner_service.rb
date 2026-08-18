class Captain::Routines::RunnerService
  # TODO: Persist runs and record checkpoints before enabling scheduled production execution. Durable state will also define
  # idempotency, retry, cancellation, and partial-run recovery semantics; the PoC intentionally executes one in-process run.
  def initialize(routine, started_at: Time.current, scheduled_for: nil, execution_id: SecureRandom.uuid, on_step: nil)
    @routine = routine
    @started_at = started_at
    @scheduled_for = scheduled_for
    @execution_id = execution_id
    @on_step = on_step
  end

  def perform
    validate!
    @runtime = Captain::Routines::RuntimeContext.new(
      routine: routine,
      id: execution_id,
      started_at: started_at,
      scheduled_for: scheduled_for,
      on_step: on_step
    )
    execute_steps(routine.dsl.fetch('steps'))

    {
      'id' => execution_id,
      'routine_id' => routine.id,
      'status' => 'completed',
      'started_at' => started_at.iso8601,
      'completed_at' => Time.current.iso8601,
      'bindings' => runtime.root_bindings,
      'trace' => runtime.trace
    }
  end

  private

  attr_reader :routine, :started_at, :scheduled_for, :execution_id, :on_step, :runtime

  def validate!
    raise Captain::Routines::InvalidDslError, 'Routine must be ready before it can run' unless routine.status_ready?

    errors = Captain::Routines::DslSchema.errors(routine.dsl)
    return if errors.empty?

    raise Captain::Routines::InvalidDslError, errors.join('; ')
  end

  def execute_steps(steps)
    steps.each_with_index do |step, index|
      path = "steps.#{index}"
      step['each'].present? ? execute_each(step, path) : execute_reduce(step, path)
    end
  end

  def execute_each(step, path)
    records = select_records(step.fetch('from'), "#{path}.from")
    runtime.record(event(path, 'map', 'started').merge('binding' => step.fetch('each'), 'records' => records.length))

    results = records.each_with_index.map do |record, index|
      execute_record_agent(step, record, "#{path}.run[#{index}]")
    end

    runtime.bind(step.fetch('collect_as'), results)
    runtime.record(event(path, 'map', 'completed').merge('records' => records.length, 'results' => results.length))
  end

  def select_records(selection, path)
    operation = Captain::Routines::Operations::Registry.fetch('conversations.search')
    filters = runtime.resolve_value(selection.fetch('where'))
    runtime.record(event(path, 'select', 'started').merge('entity' => selection.fetch('select')))
    records = operation.execute(context: runtime, arguments: filters)
    runtime.record(event(path, 'select', 'completed').merge('entity' => selection.fetch('select'), 'records' => records.length))
    records
  rescue StandardError => e
    raise Captain::Routines::OperationError, "Conversation selection failed: #{e.message}"
  end

  def execute_record_agent(step, record, path)
    record_id = record.fetch('id')
    runtime.record(event(path, 'agent', 'started').merge('record_id' => record_id))
    result = record_agent_result(step, record, path)
    status = result.fetch('status') == 'failed' ? 'failed' : 'completed'
    record_agent_event(path, record_id, result, status, error: (result['reason'] if status == 'failed'))
    result
  rescue StandardError => e
    result = failed_agent_result(record, e.message)
    record_agent_event(path, record.fetch('id'), result, 'failed', error: e.message)
    result
  end

  def record_agent_result(step, record, path)
    response = Captain::Routines::RecordAgentService.new(
      account: routine.account,
      instruction: step.dig('run', 'instruction'),
      result_contract: step.dig('run', 'result'),
      record: record,
      runtime: runtime,
      path: path
    ).perform
    response[:result] || failed_agent_result(record, response[:error])
  end

  def record_agent_event(path, record_id, result, status, error: nil)
    runtime.record(
      event(path, 'agent', status).merge(
        'record_id' => record_id,
        'outcome' => result.fetch('outcome'),
        'receipts' => result.fetch('receipts').length,
        'error' => error
      ).compact
    )
  end

  def execute_reduce(step, path)
    results = runtime.resolve(step.dig('reduce', 'ref'))
    raise Captain::Routines::ExecutionError, "Reduction source at #{path} is not a collection" unless results.is_a?(Array)

    runtime.record(event(path, 'reduce', 'started').merge('results' => results.length))
    response = reducer(step, results).perform
    raise Captain::Routines::LlmError, response[:error] if response[:error]

    runtime.bind(step.fetch('save_as'), response.fetch(:result))
    runtime.record(event(path, 'reduce', 'completed').merge('results' => results.length))
  end

  def event(path, type, status)
    { 'path' => path, 'type' => type, 'status' => status, 'at' => Time.current.iso8601 }
  end

  def reducer(step, results)
    Captain::Routines::ReducerService.new(
      account: routine.account,
      instruction: step.dig('run', 'instruction'),
      results: results,
      execution_context: runtime.execution
    )
  end

  def failed_agent_result(record, error)
    {
      'record_id' => record.fetch('id'),
      'status' => 'failed',
      'outcome' => Captain::Routines::AgentRunSchema::FAILURE_OUTCOME,
      'reason' => error.to_s,
      'data' => {},
      'receipts' => []
    }
  end
end
