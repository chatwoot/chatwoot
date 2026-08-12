class Captain::Routines::DslBuilderService
  class InvalidClarificationAnswersError < StandardError; end

  def initialize(routine, on_stage: nil)
    @routine = routine
    @on_stage = on_stage
  end

  def perform(answers: {})
    return result if @routine.status_ready?
    return result unless apply_clarification_answers(answers)

    @routine.update!(status: :building)
    plan_outcome = Captain::Routines::SemanticPlanBuilderService.new(@routine, on_stage: @on_stage).perform
    return result unless plan_outcome == :accepted

    Captain::Routines::DslCompilerService.new(@routine, on_stage: @on_stage).perform
    result
  rescue InvalidClarificationAnswersError => e
    result.merge(error: e.message)
  rescue StandardError => e
    fail_build(e.message)
  end

  private

  def apply_clarification_answers(answers)
    return true unless @routine.status_awaiting_clarification?
    return false if answers.blank?

    answers = answers.to_h.stringify_keys
    question_ids = @routine.clarification_questions.pluck('id')
    unknown_ids = answers.keys - question_ids
    raise InvalidClarificationAnswersError, "Unknown clarification answer IDs: #{unknown_ids.join(', ')}" if unknown_ids.any?

    merged_answers = @routine.clarification_answers.merge(answers)
    unanswered_questions = @routine.clarification_questions.reject do |question|
      merged_answers[question['id']].present?
    end

    @routine.update!(
      clarification_answers: merged_answers,
      clarification_questions: unanswered_questions
    )
    unanswered_questions.empty?
  end

  def fail_build(error)
    evaluation = Captain::Routines::BuildEvaluation.failed(error)
    @routine.update!(status: :failed, evaluation: evaluation)
    result
  end

  def result
    {
      status: @routine.status,
      routine: @routine,
      semantic_plan: @routine.semantic_plan,
      plan_evaluation: @routine.plan_evaluation,
      dsl: @routine.dsl,
      evaluation: @routine.evaluation,
      questions: @routine.clarification_questions
    }
  end
end
