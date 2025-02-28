class Internal::AccountAnalysis::ContentEvaluatorService < Llm::BaseOpenAiService
  def initialize
    super()

    @model = 'gpt-4o-mini'.freeze
  end

  def evaluate(content)
    return default_evaluation if content.blank?

    begin
      response = send_to_llm(content)
      evaluation = handle_response(response)
      log_evaluation_results(evaluation)
      evaluation
    rescue StandardError => e
      handle_evaluation_error(e)
    end
  end

  private

  def send_to_llm(content)
    Rails.logger.info('Sending content to LLM for security evaluation')
    @client.chat(
      parameters: {
        model: @model,
        messages: llm_messages(content),
        response_format: { type: 'json_object' }
      }
    )
  end

  def handle_response(response)
    return default_evaluation if response.nil?

    parsed = JSON.parse(response.dig('choices', 0, 'message', 'content').strip)

    {
      'threat_level' => parsed['threat_level'] || 'unknown',
      'threat_summary' => parsed['threat_summary'] || 'No threat summary provided',
      'detected_threats' => parsed['detected_threats'] || [],
      'illegal_activities_detected' => parsed['illegal_activities_detected'] || false,
      'recommendation' => parsed['recommendation'] || 'review'
    }
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
    Rails.logger.info("LLM evaluation - Level: #{evaluation['threat_level']}, Illegal activities: #{evaluation['illegal_activities_detected']}")
  end

  def handle_evaluation_error(error)
    Rails.logger.error("Error evaluating content: #{error.message}")
    default_evaluation('evaluation_failure')
  end

  def llm_messages(content)
    [
      { role: 'system', content: 'You are a security analysis system that evaluates content for potential threats and scams.' },
      { role: 'user', content: Internal::AccountAnalysis::PromptsService.threat_analyser(content.to_s[0...10_000]) }
    ]
  end
end
