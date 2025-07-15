module Captain::Llm::Concerns::PdfResponsesApi
  extend ActiveSupport::Concern

  RESPONSES_API_URL = 'https://api.openai.com'.freeze
  RESPONSES_API_ENDPOINT = '/v1/responses'.freeze
  API_KEY_CONFIG_NAME = 'CAPTAIN_OPEN_AI_API_KEY'.freeze

  private

  def process_pdf_with_responses_api
    request_body = build_pdf_request_body
    response = call_responses_api(request_body)
    handle_api_response(response)
  end

  def build_pdf_request_body
    {
      model: @model,
      input: [
        build_system_input,
        build_user_input_for_pdf
      ],
      text: {
        format: { type: 'json_object' }
      }
    }
  end

  def build_system_input
    {
      role: 'system',
      content: Captain::Llm::SystemPromptsService.faq_generator
    }
  end

  def build_user_input_for_pdf
    {
      role: 'user',
      content: [
        { type: 'input_file', file_id: metadata[:openai_file_id] },
        { type: 'input_text', text: build_analysis_prompt }
      ]
    }
  end

  def build_analysis_prompt
    if metadata[:processing_instruction]
      "#{pdf_analysis_prompt} #{metadata[:processing_instruction]}"
    else
      pdf_analysis_prompt
    end
  end

  def pdf_analysis_prompt
    'Please analyze this PDF document and generate comprehensive FAQs based on its content.'
  end

  def call_responses_api(request_body)
    responses_api_connection.post(RESPONSES_API_ENDPOINT) do |req|
      req.headers['Authorization'] = "Bearer #{api_key}"
      req.headers['Content-Type'] = 'application/json'
      req.body = request_body
    end
  end

  def responses_api_connection
    @responses_api_connection ||= Faraday.new(url: RESPONSES_API_URL) do |faraday|
      faraday.request :json
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end
  end

  def api_key
    @api_key ||= InstallationConfig.find_by!(name: API_KEY_CONFIG_NAME).value
  rescue ActiveRecord::RecordNotFound
    raise OpenAI::Error, "API key configuration not found: #{API_KEY_CONFIG_NAME}"
  end

  def handle_api_response(response)
    return response.body if response.status == 200

    error_message = extract_error_message(response)
    Rails.logger.error "OpenAI Responses API error: #{response.status} - #{error_message}"
    raise OpenAI::Error, "Responses API error: #{response.status} - #{error_message}"
  end

  def extract_error_message(response)
    body = response.body
    return body unless body.is_a?(Hash)

    body.dig('error', 'message') || body['error'] || body.to_s
  rescue StandardError
    response.body.to_s
  end

  def extract_content_from_responses_api(response)
    output_message = Array(response['output']).first
    return nil unless output_message

    content_item = output_message['content']&.find { |c| c['type'] == 'output_text' }
    content_item&.dig('text')
  end
end