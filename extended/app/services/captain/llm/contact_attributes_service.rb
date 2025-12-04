class Captain::Llm::ContactAttributesService < Llm::BaseService
  pattr_initialize [:contact!, :conversation!]

  def perform
    return { attributes: [] } if conversation.messages.empty?

    generate_attributes
  end

  private

  def generate_attributes
      response_format: { type: 'json_object' },
      messages: [
        {
          role: 'system',
          content: prompt
        },
        {
          role: 'user',
          content: content
        }
      ]
    }
  end

  def parse_response(response)
    content = response.dig('choices', 0, 'message', 'content')
    return [] if content.nil?

    JSON.parse(content.strip).fetch('attributes', [])
  rescue JSON::ParserError => e
    Rails.logger.error "Error in parsing GPT processed response: #{e.message}"
    []
  end
end
