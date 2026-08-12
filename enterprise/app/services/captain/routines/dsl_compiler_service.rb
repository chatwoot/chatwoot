class Captain::Routines::DslCompilerService
  MAX_COMPILATION_PASSES = 4

  def initialize(routine, on_stage: nil)
    @routine = routine
    @on_stage = on_stage
  end

  def perform
    validator_feedback = nil

    MAX_COMPILATION_PASSES.times do |pass|
      outcome, validator_feedback = compile_and_validate(pass + 1, validator_feedback)
      return outcome if outcome
    end

    @routine.update!(status: :needs_review)
    :needs_review
  end

  private

  def compile_and_validate(attempt, validator_feedback)
    response = compile(attempt, validator_feedback)
    return [fail_compilation(response[:error]), nil] if response[:error]

    persist_dsl(response[:dsl])
    evaluation = validate_dsl
    return [mark_ready, evaluation] if evaluation['status'] == 'valid'

    [nil, evaluation]
  end

  def compile(attempt, validator_feedback)
    emit(
      :compiling_dsl,
      attempt: attempt,
      maximum: MAX_COMPILATION_PASSES,
      repairing: validator_feedback.present?
    )
    Captain::Routines::DslGeneratorService.new(
      account: @routine.account,
      semantic_plan: @routine.semantic_plan,
      current_dsl: validator_feedback.present? ? @routine.dsl.presence : nil,
      validator_feedback: validator_feedback
    ).perform
  end

  def persist_dsl(dsl)
    @routine.update!(dsl: dsl, name: dsl['name'])
    emit(:dsl_compiled, dsl: @routine.dsl)
  end

  def validate_dsl
    emit(:validating_dsl)
    errors = Captain::Routines::DslSchema.errors(@routine.dsl)
    evaluation = if errors.empty?
                   Captain::Routines::BuildEvaluation.valid(
                     'The DSL satisfies the schema, operation contracts, references, cardinality, and approval requirements.'
                   )
                 else
                   Captain::Routines::BuildEvaluation.correctable(
                     'The compiled DSL does not satisfy the deterministic Routine contract.',
                     errors
                   )
                 end
    @routine.update!(evaluation: evaluation)
    log_evaluation(evaluation)
    emit(:dsl_validated, evaluation: evaluation)
    evaluation
  end

  def log_evaluation(evaluation)
    iteration = @routine.build_iterations + 1
    entry = {
      'iteration' => iteration,
      'phase' => 'dsl',
      'dsl' => @routine.dsl,
      'evaluation' => evaluation,
      'created_at' => Time.current.iso8601
    }
    @routine.update!(build_iterations: iteration, build_log: @routine.build_log + [entry])
  end

  def mark_ready
    @routine.update!(status: :ready, clarification_questions: [])
    :ready
  end

  def fail_compilation(error)
    @routine.update!(status: :failed, evaluation: Captain::Routines::BuildEvaluation.failed(error))
    :failed
  end

  def emit(stage, details = {})
    @on_stage&.call(stage, details)
  end
end
