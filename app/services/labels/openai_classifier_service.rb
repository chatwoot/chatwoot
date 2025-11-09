# frozen_string_literal: true

class Labels::OpenaiClassifierService
  pattr_initialize [:conversation!, :account!]

  def suggest_labels
    return { labels: [] } unless should_process?

    response = call_openai_api
    parse_response(response)
  rescue StandardError => e
    Rails.logger.error("OpenAI label classification failed: #{e.message}")
    { labels: [] }
  end

  private

  def should_process?
    return false if conversation.messages.incoming.count < 3
    return false if conversation.messages.count > 100
    return false if available_labels.empty?

    true
  end

  def call_openai_api
    client.chat(
      parameters: {
        model: 'gpt-4o-mini',
        messages: build_messages,
        temperature: 0.3,
        response_format: {
          type: 'json_schema',
          json_schema: {
            name: 'label_classification',
            strict: true,
            schema: response_schema
          }
        }
      }
    )
  end

  def build_messages
    [
      { role: 'system', content: system_prompt },
      *conversation_messages
    ]
  end

  def system_prompt
    <<~PROMPT
      You are a customer support conversation classifier. Your task is to analyze the conversation
      and select the most relevant labels from the provided list.

      Available labels: #{available_labels.join(', ')}

      Rules:
      - Select up to 2 most relevant labels
      - Use EXACT label names from the available list (preserve casing)
      - Return empty array if no labels match well
      - Base your decision on the conversation content and context
    PROMPT
  end

  def conversation_messages
    # Get last 20 messages to stay within token limits
    messages = conversation.messages.chat.last(20)

    messages.map do |message|
      {
        role: message.incoming? ? 'user' : 'assistant',
        content: message.content || ''
      }
    end
  end

  def response_schema
    {
      type: 'object',
      properties: {
        labels: {
          type: 'array',
          description: 'Array of selected label names',
          items: {
            type: 'string',
            enum: available_labels
          },
          maxItems: 2
        },
        reasoning: {
          type: 'string',
          description: 'Brief explanation of why these labels were chosen (optional)'
        }
      },
      required: ['labels'],
      additionalProperties: false
    }
  end

  def parse_response(response)
    content = response.dig('choices', 0, 'message', 'content')
    return { labels: [] } if content.blank?

    parsed = JSON.parse(content)
    {
      labels: parsed['labels'] || [],
      reasoning: parsed['reasoning']
    }
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse OpenAI response: #{e.message}")
    { labels: [] }
  end

  def available_labels
    @available_labels ||= account.labels.pluck(:title)
  end

  def client
    @client ||= OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY', nil))
  end
end
