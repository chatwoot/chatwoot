class Internal::AccountAnalysis::ContentEvaluatorService
  include Integrations::LlmInstrumentation

  def initialize
    Llm::Config.initialize!
  end

  def evaluate(content)
    return default_evaluation if content.blank?

    moderation_result = instrument_moderation_call(instrumentation_params(content)) do
      RubyLLM.moderate(content.to_s[0...10_000])
    end

    build_evaluation(moderation_result)
  rescue StandardError => e
    handle_evaluation_error(e)
  end

  private

  def instrumentation_params(content)
    {
      span_name: 'llm.internal.content_moderation',
      model: 'text-moderation-latest',
      input: content,
      feature_name: 'content_evaluator'
    }
  end

  def build_evaluation(result)
    flagged = result.flagged?
    categories = result.flagged_categories

    evaluation = {
      'threat_level' => flagged ? determine_threat_level(result) : 'safe',
      'threat_summary' => flagged ? "Content flagged for: #{categories.join(', ')}" : 'No threats detected',
      'detected_threats' => categories,
      'illegal_activities_detected' => categories.any? { |c| c.include?('violence') || c.include?('self-harm') },
      'recommendation' => flagged ? 'review' : 'approve'
    }

    log_evaluation_results(evaluation)
    evaluation
  end

  def determine_threat_level(result)
    scores = result.category_scores
    max_score = scores.values.max || 0

    case max_score
    when 0.8.. then 'critical'
    when 0.5..0.8 then 'high'
    when 0.2..0.5 then 'medium'
    else 'low'
    end
  end

  def default_evaluation(error_type = nil)
    {
      'threat_level' => 'unknown',
      'threat_summary' => 'Failed to complete content evaluation',
      'detected_threats' => error_type ? [error_type] : [],
      'illegal_activities_detected' => false,
      'recommendation' => 'review'
    }
  end

  def log_evaluation_results(evaluation)
    Rails.logger.info("Moderation evaluation - Level: #{evaluation['threat_level']}, Threats: #{evaluation['detected_threats'].join(', ')}")
  end

  def handle_evaluation_error(error)
    Rails.logger.error("Error evaluating content: #{error.message}")
    default_evaluation('evaluation_failure')
  end
end
