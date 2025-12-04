# frozen_string_literal: true

class Captain::Llm::ContactAttributesService < Llm::BaseService
  pattr_initialize [:contact!, :conversation!]

  def perform
    return { attributes: [] } if conversation.messages.empty?

    generate_attributes
  end

  private

  def generate_attributes
    # TODO: Implement contact attributes generation
    # This service should analyze conversation messages and extract contact attributes
    raise NotImplementedError, 'Contact attributes service is not yet implemented'
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
