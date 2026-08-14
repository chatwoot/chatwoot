class Captain::Routines::RunnerService
  # TODO: Persist runs and step checkpoints before enabling scheduled production execution. Durable state will also define
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
    execute_steps(routine.dsl.fetch('steps'), 'steps')

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

  def execute_steps(steps, parent_path)
    steps.each_with_index { |step, index| execute_step(step, "#{parent_path}.#{index}") }
  end

  def execute_step(step, path)
    return execute_each(step, path) if step.key?('each')
    return execute_operation(step, path) if step.key?('operation')
    return execute_decision(step, path) if step.key?('decide')
    return execute_composition(step, path) if step.key?('compose')
    return execute_condition(step, path) if step.key?('when')

    raise Captain::Routines::ExecutionError, "Unknown step at #{path}"
  end

  def execute_each(step, path)
    collection = loop_collection(step.fetch('from'), path)
    runtime.record(event(path, 'each', 'started').merge('binding' => step.fetch('each'), 'items' => collection.length))
    collection.each_with_index do |item, index|
      runtime.with_frame(step.fetch('each') => item) do
        execute_steps(step.fetch('do'), "#{path}.do[#{index}]")
      end
    end
    runtime.record(event(path, 'each', 'completed').merge('items' => collection.length))
  end

  def loop_collection(source, path)
    value = if source.key?('ref')
              runtime.resolve(source.fetch('ref'))
            else
              perform_operation(source.fetch('operation'), source.fetch('with'), "#{path}.from")
            end
    raise Captain::Routines::ExecutionError, "Loop source at #{path} did not return a collection" unless value.is_a?(Array)

    value
  end

  def execute_operation(step, path)
    result = perform_operation(step.fetch('operation'), step.fetch('with'), path)
    runtime.bind(step.fetch('save_as'), result) if step['save_as'].present?
    result
  end

  def perform_operation(name, arguments, path)
    operation = Captain::Routines::Operations::Registry.fetch(name)
    raise Captain::Routines::OperationError, "Operation '#{name}' is not available" unless operation

    runtime.record(event(path, 'operation', 'started').merge('operation' => name, 'effect' => operation.effect))
    result = operation.execute(context: runtime, arguments: runtime.resolve_value(arguments))
    runtime.record(event(path, 'operation', 'completed').merge('operation' => name, 'effect' => operation.effect))
    result
  rescue Captain::Routines::ExecutionError
    raise
  rescue StandardError => e
    raise Captain::Routines::OperationError, "#{name} failed: #{e.message}"
  end

  def execute_decision(step, path)
    # TODO: Convert quota, configuration, and provider failures into typed execution failures once production retry semantics exist.
    runtime.record(event(path, 'decide', 'started').merge('decision' => step.fetch('decide')))
    context = decision_context(step)
    result = decision_service(step, context).perform
    runtime.bind(step.fetch('decide'), result.fetch('choice'))
    runtime.record(event(path, 'decide', 'completed').merge('decision' => step.fetch('decide'), 'choice' => result.fetch('choice')))
  end

  def decision_service(step, context)
    Captain::Routines::DecisionService.new(
      account: routine.account,
      instruction: step['instruction'].presence || "Choose the best outcome for #{step.fetch('decide')}",
      choices: step.fetch('choices'),
      context: context,
      execution_context: runtime.execution
    )
  end

  def decision_context(step)
    return { 'about' => runtime.resolve(step.dig('about', 'ref')) } if step['about']

    resolve_named_references(step.fetch('context'))
  end

  def execute_composition(step, path)
    # TODO: Convert quota, configuration, and provider failures into typed execution failures once production retry semantics exist.
    runtime.record(event(path, 'compose', 'started').merge('composition' => step.fetch('compose')))
    mentions = resolve_named_references(step.fetch('mention_bindings', {}))
    result = compose_service(step, mentions).perform
    runtime.bind(step.fetch('compose'), result)
    runtime.record(event(path, 'compose', 'completed').merge('composition' => step.fetch('compose'), 'segments' => result.fetch('segments').length))
  end

  def compose_service(step, mentions)
    Captain::Routines::ComposeService.new(
      account: routine.account,
      instruction: step.fetch('instruction'),
      context: resolve_named_references(step.fetch('context')),
      mention_bindings: mentions,
      required_mentions: step.fetch('required_mentions', []),
      routine_id: routine.id,
      composition: step.fetch('compose'),
      execution_context: runtime.execution
    )
  end

  def resolve_named_references(references)
    references.transform_values { |reference| runtime.resolve(reference.fetch('ref')) }
  end

  def execute_condition(step, path)
    condition = step.fetch('when')
    matched = runtime.resolve(condition.fetch('ref')) == runtime.resolve_value(condition.fetch('equals'))
    branch = matched ? 'do' : 'else'
    runtime.record(event(path, 'when', 'completed').merge('matched' => matched, 'branch' => branch))
    execute_steps(step.fetch(branch, []), "#{path}.#{branch}")
  end

  def event(path, type, status)
    { 'path' => path, 'type' => type, 'status' => status, 'at' => Time.current.iso8601 }
  end
end
