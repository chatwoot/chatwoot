class Captain::Llm::ResponseFormatSchema
  class << self
    def faq(name: 'faq_generator_response')
      build_schema(
        name: name,
        properties: { faqs: faq_items_schema },
        required: ['faqs']
      )
    end

    def notes
      build_schema(
        name: 'contact_notes_response',
        properties: { notes: array_of_strings_schema },
        required: ['notes']
      )
    end

    def attributes
      build_schema(
        name: 'contact_attributes_response',
        properties: { attributes: attributes_schema },
        required: ['attributes']
      )
    end

    def paginated_chunk
      build_schema(
        name: 'paginated_faq_chunk_response',
        properties: {
          faqs: faq_items_schema,
          has_content: { type: 'boolean' }
        },
        required: %w[faqs has_content]
      )
    end

    private

    def build_schema(name:, properties:, required:)
      {
        type: 'json_schema',
        json_schema: {
          name: name,
          strict: true,
          schema: {
            type: 'object',
            properties: properties,
            required: required,
            additionalProperties: false
          }
        }
      }
    end

    def faq_items_schema
      {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            question: { type: 'string' },
            answer: { type: 'string' }
          },
          required: %w[question answer],
          additionalProperties: false
        }
      }
    end

    def array_of_strings_schema
      {
        type: 'array',
        items: { type: 'string' }
      }
    end

    def attributes_schema
      {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            attribute: { type: 'string' },
            value: { type: 'string' }
          },
          required: %w[attribute value],
          additionalProperties: false
        }
      }
    end
  end
end
