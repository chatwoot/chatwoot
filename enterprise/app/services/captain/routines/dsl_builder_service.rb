class Captain::Routines::DslBuilderService
  class InvalidClarificationAnswersError < StandardError; end

  MIN_CONSECUTIVE_VALIDATIONS = 2
  MAX_EVALUATION_PASSES = 4

  def initialize(routine)
    @routine = routine
  end

  def perform(answers: {})
    return result if @routine.status_ready?
    return result unless apply_clarification_answers(answers)

    @routine.update!(status: :building)
    generation = generate_dsl(evaluator_feedback: @routine.evaluation.presence)
    return fail_build(generation[:error]) if generation[:error]

    persist_dsl(generation[:dsl])
    evaluate_until_settled
  rescue InvalidClarificationAnswersError => e
    result.merge(error: e.message)
  rescue StandardError => e
    fail_build(e.message)
  end

  private

  def evaluate_until_settled
    MAX_EVALUATION_PASSES.times do
      evaluation_response = evaluate_dsl
      return fail_build(evaluation_response[:error]) if evaluation_response[:error]

      evaluation = evaluation_response[:evaluation]
      log_evaluation(evaluation)

      case evaluation['status']
      when 'valid'
        return mark_ready if consecutive_validations >= MIN_CONSECUTIVE_VALIDATIONS
      when 'correctable'
        generation = generate_dsl(evaluator_feedback: evaluation)
        return fail_build(generation[:error]) if generation[:error]

        persist_dsl(generation[:dsl])
      when 'needs_clarification'
        return pause_for_clarification(evaluation)
      end
    end

    @routine.update!(status: :needs_review)
    result
  end

  def generate_dsl(evaluator_feedback:)
    Captain::Routines::DslGeneratorService.new(
      account: @routine.account,
      instructions: @routine.instructions,
      current_dsl: @routine.dsl.presence,
      evaluator_feedback: evaluator_feedback,
      clarification_answers: @routine.clarification_answers
    ).perform
  end

  def evaluate_dsl
    Captain::Routines::DslEvaluatorService.new(
      account: @routine.account,
      instructions: @routine.instructions,
      dsl: @routine.dsl,
      clarification_answers: @routine.clarification_answers
    ).perform
  end

  def persist_dsl(dsl)
    @routine.update!(dsl: dsl, name: dsl['name'])
  end

  def log_evaluation(evaluation)
    iteration = @routine.build_iterations + 1
    entry = {
      'iteration' => iteration,
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

  def consecutive_validations
    @routine.build_log.reverse.take_while do |entry|
      entry.dig('evaluation', 'status') == 'valid'
    end.size
  end

  def pause_for_clarification(evaluation)
    questions = evaluation['questions'].reject do |question|
      @routine.clarification_answers[question['id']].present?
    end

    if questions.empty?
      @routine.update!(status: :needs_review)
    else
      @routine.update!(status: :awaiting_clarification, clarification_questions: questions)
    end

    result
  end

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

  def mark_ready
    @routine.update!(status: :ready, clarification_questions: [])
    result
  end

  def fail_build(error)
    evaluation = { 'status' => 'failed', 'summary' => error.to_s, 'corrections' => [], 'questions' => [] }
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
