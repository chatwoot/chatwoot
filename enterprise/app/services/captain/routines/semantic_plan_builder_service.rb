class Captain::Routines::SemanticPlanBuilderService
  MIN_CONSECUTIVE_VALIDATIONS = 2
  MAX_EVALUATION_PASSES = 4

  def initialize(routine, on_stage: nil)
    @routine = routine
    @on_stage = on_stage
  end

  def perform
    return reuse_plan if accepted_plan?

    return fail_plan(initial_generation[:error]) if initial_generation[:error]

    evaluate_until_settled
  end

  private

  def initial_generation
    @initial_generation ||= generate_plan(feedback: @routine.plan_evaluation.presence).tap do |generation|
      persist_plan(generation[:plan]) unless generation[:error]
    end
  end

  def evaluate_until_settled
    MAX_EVALUATION_PASSES.times do |pass|
      outcome = evaluate_plan(pass + 1)
      return outcome if outcome
    end

    @routine.update!(status: :needs_review)
    :needs_review
  end

  def evaluate_plan(attempt)
    emit(:evaluating_plan, attempt: attempt, maximum: MAX_EVALUATION_PASSES)
    response = evaluator.perform
    return fail_plan(response[:error]) if response[:error]

    evaluation = response[:evaluation]
    @routine.update!(plan_evaluation: evaluation)
    log_evaluation(evaluation)
    emit(:plan_evaluated, evaluation: evaluation)
    process_evaluation(evaluation)
  end

  def process_evaluation(evaluation)
    case evaluation['status']
    when 'valid' then accept_plan_if_stable
    when 'correctable' then repair_plan(evaluation)
    when 'needs_clarification' then pause_for_clarification(evaluation)
    when 'unsupported' then mark_needs_review
    end
  end

  def accept_plan_if_stable
    return unless consecutive_validations >= MIN_CONSECUTIVE_VALIDATIONS

    emit(:plan_accepted, plan: @routine.semantic_plan)
    :accepted
  end

  def repair_plan(evaluation)
    generation = generate_plan(feedback: evaluation, stage: :repairing_plan)
    return fail_plan(generation[:error]) if generation[:error]

    persist_plan(generation[:plan])
    nil
  end

  def generate_plan(feedback:, stage: :planning)
    emit(stage)
    Captain::Routines::SemanticPlanGeneratorService.new(
      account: @routine.account,
      instructions: @routine.instructions,
      current_plan: @routine.semantic_plan.presence,
      evaluator_feedback: feedback,
      clarification_answers: @routine.clarification_answers
    ).perform
  end

  def evaluator
    Captain::Routines::SemanticPlanEvaluatorService.new(
      account: @routine.account,
      instructions: @routine.instructions,
      plan: @routine.semantic_plan,
      clarification_answers: @routine.clarification_answers
    )
  end

  def persist_plan(plan)
    @routine.update!(semantic_plan: plan, name: plan['name'])
    emit(:plan_generated, plan: @routine.semantic_plan)
  end

  def log_evaluation(evaluation)
    iteration = @routine.build_iterations + 1
    entry = {
      'iteration' => iteration,
      'phase' => 'semantic_plan',
      'semantic_plan' => @routine.semantic_plan,
      'evaluation' => evaluation,
      'created_at' => Time.current.iso8601
    }
    @routine.update!(build_iterations: iteration, build_log: @routine.build_log + [entry])
  end

  def consecutive_validations
    @routine.build_log.reverse.take_while do |entry|
      entry['phase'] == 'semantic_plan' && entry.dig('evaluation', 'status') == 'valid'
    end.size
  end

  def accepted_plan?
    @routine.semantic_plan.present? && consecutive_validations >= MIN_CONSECUTIVE_VALIDATIONS
  end

  def reuse_plan
    emit(:plan_reused, plan: @routine.semantic_plan)
    :accepted
  end

  def pause_for_clarification(evaluation)
    questions = evaluation['questions'].reject do |question|
      clarification_answered?(@routine.clarification_answers[question['id']])
    end

    status = questions.empty? ? :needs_review : :awaiting_clarification
    @routine.update!(status: status, clarification_questions: questions)
    status
  end

  def clarification_answered?(value)
    value.is_a?(Hash) ? value['answer'].present? : value.present?
  end

  def mark_needs_review
    @routine.update!(status: :needs_review)
    :needs_review
  end

  def fail_plan(error)
    evaluation = Captain::Routines::BuildEvaluation.failed(error)
    @routine.update!(status: :failed, plan_evaluation: evaluation, evaluation: evaluation)
    :failed
  end

  def emit(stage, details = {})
    @on_stage&.call(stage, details)
  end
end
