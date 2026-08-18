class Captain::Routines::DslBuilderService
  class InvalidClarificationAnswersError < StandardError; end

  def initialize(routine, on_stage: nil)
    @routine = routine
    @on_stage = on_stage
  end

  def perform(answers: {})
    return result if reusable_dsl?
    return result unless apply_clarification_answers(answers)

    @routine.update!(status: :building, semantic_plan: {}, plan_evaluation: {}, evaluation: {})
    Captain::Routines::DslCompilerService.new(@routine, on_stage: @on_stage).perform
    result
  rescue InvalidClarificationAnswersError => e
    result.merge(error: e.message)
  rescue StandardError => e
    fail_build(e.message)
  end

  private

  def reusable_dsl?
    @routine.status_ready? && @routine.semantic_plan.blank? && @routine.plan_evaluation.blank? &&
      Captain::Routines::DslSchema.valid?(@routine.dsl)
  end

  def apply_clarification_answers(answers)
    return true unless @routine.status_awaiting_clarification?
    return false if answers.blank?

    answers = answers.to_h.stringify_keys
    validate_answer_ids!(answers)
    merged_answers = @routine.clarification_answers.merge(answered_questions(answers))
    unanswered_questions = @routine.clarification_questions.reject do |question|
      clarification_answered?(merged_answers[question['id']])
    end

    @routine.update!(
      clarification_answers: merged_answers,
      clarification_questions: unanswered_questions
    )
    unanswered_questions.empty?
  end

  def validate_answer_ids!(answers)
    question_ids = @routine.clarification_questions.pluck('id')
    unknown_ids = answers.keys - question_ids
    raise InvalidClarificationAnswersError, "Unknown clarification answer IDs: #{unknown_ids.join(', ')}" if unknown_ids.any?
  end

  def answered_questions(answers)
    questions_by_id = @routine.clarification_questions.index_by { |question| question.fetch('id') }
    answers.to_h do |id, answer|
      [id, { 'question' => questions_by_id.fetch(id).fetch('question'), 'answer' => answer }]
    end
  end

  def clarification_answered?(value)
    value.is_a?(Hash) ? value['answer'].present? : value.present?
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
      dsl: @routine.dsl,
      evaluation: @routine.evaluation,
      questions: @routine.clarification_questions
    }
  end
end
