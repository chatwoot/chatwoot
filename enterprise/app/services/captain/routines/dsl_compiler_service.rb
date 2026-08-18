class Captain::Routines::DslCompilerService
  MAX_COMPILATION_PASSES = 4

  def initialize(routine, on_stage: nil)
    @routine = routine
    @on_stage = on_stage
  end

  def perform
    validator_feedback = nil
    evaluator_feedback = nil

    MAX_COMPILATION_PASSES.times do |pass|
      outcome, validator_feedback, evaluator_feedback = build_pass(
        pass + 1,
        validator_feedback,
        evaluator_feedback
      )
      return outcome if outcome
    end

    @routine.update!(status: :needs_review)
    :needs_review
  end

  private

  def build_pass(attempt, validator_feedback, evaluator_feedback)
    response = compile(attempt, validator_feedback, evaluator_feedback)
    return [fail_compilation(response[:error]), nil, nil] if response[:error]

    persist_dsl(response[:dsl])
    clarification_outcome = pause_for_questions(response[:questions], phase: 'dsl_generation')
    return [clarification_outcome, nil, nil] if clarification_outcome

    validation = validate_dsl
    return [nil, validation, nil] unless validation['status'] == 'valid'

    review_response = review_dsl
    return [fail_compilation(review_response[:error]), nil, nil] if review_response[:error]

    evaluation = review_response.fetch(:evaluation)
    persist_evaluation(evaluation, phase: 'dsl_semantics')
    emit(:dsl_evaluated, evaluation: evaluation)
    process_semantic_evaluation(evaluation)
  end

  def compile(attempt, validator_feedback, evaluator_feedback)
    repairing = validator_feedback.present? || evaluator_feedback.present? || @routine.clarification_answers.present?
    emit(:compiling_dsl, attempt: attempt, maximum: MAX_COMPILATION_PASSES, repairing: repairing)
    Captain::Routines::DslGeneratorService.new(
      account: @routine.account,
      instructions: @routine.instructions,
      current_dsl: (repairing ? @routine.dsl.presence : nil),
      validator_feedback: validator_feedback,
      evaluator_feedback: evaluator_feedback,
      clarification_answers: @routine.clarification_answers
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
                     'The DSL satisfies the schema, selection filters, references, and binding requirements.'
                   )
                 else
                   Captain::Routines::BuildEvaluation.correctable(
                     'The compiled DSL does not satisfy the deterministic Routine contract.',
                     errors
                   )
                 end
    persist_evaluation(evaluation, phase: 'dsl_validation')
    emit(:dsl_validated, evaluation: evaluation)
    evaluation
  end

  def review_dsl
    emit(:evaluating_dsl)
    Captain::Routines::DslEvaluatorService.new(
      account: @routine.account,
      instructions: @routine.instructions,
      dsl: @routine.dsl,
      clarification_answers: @routine.clarification_answers
    ).perform
  end

  def process_semantic_evaluation(evaluation)
    case evaluation['status']
    when 'valid'
      [mark_ready, nil, nil]
    when 'correctable'
      [nil, nil, evaluation]
    when 'needs_clarification'
      [pause_for_questions(evaluation['questions'], evaluation: evaluation, phase: 'dsl_semantics', persist: false), nil, nil]
    else
      [mark_needs_review, nil, nil]
    end
  end

  def pause_for_questions(questions, phase:, evaluation: nil, persist: true)
    questions = Array(questions).reject do |question|
      clarification_answered?(@routine.clarification_answers[question['id']])
    end
    return if questions.empty?

    evaluation ||= {
      'status' => 'needs_clarification',
      'summary' => 'A blocking administrator choice is required before the DSL can be completed.',
      'corrections' => [],
      'questions' => questions,
      'missing_capabilities' => []
    }
    persist_evaluation(evaluation, phase: phase) if persist
    @routine.update!(status: :awaiting_clarification, clarification_questions: questions)
    :awaiting_clarification
  end

  def clarification_answered?(value)
    value.is_a?(Hash) ? value['answer'].present? : value.present?
  end

  def persist_evaluation(evaluation, phase:)
    iteration = @routine.build_iterations + 1
    entry = {
      'iteration' => iteration,
      'phase' => phase,
      'dsl' => @routine.dsl,
      'evaluation' => evaluation,
      'created_at' => Time.current.iso8601
    }
    @routine.update!(
      evaluation: evaluation,
      build_iterations: iteration,
      build_log: @routine.build_log + [entry]
    )
  end

  def mark_ready
    @routine.update!(status: :ready, clarification_questions: [])
    :ready
  end

  def mark_needs_review
    @routine.update!(status: :needs_review)
    :needs_review
  end

  def fail_compilation(error)
    @routine.update!(status: :failed, evaluation: Captain::Routines::BuildEvaluation.failed(error))
    :failed
  end

  def emit(stage, details = {})
    @on_stage&.call(stage, details)
  end
end
