require 'gemini-ai'

class Captain::Llm::Providers::GeminiProvider < Captain::Llm::Providers::BaseProvider
  # Model mapping
  MODELS = {
    'gpt-4o' => 'gemini-1.5-pro',
    'gpt-4o-mini' => 'gemini-1.5-flash',
    'gpt-4-turbo' => 'gemini-1.5-pro',
    'gpt-3.5-turbo' => 'gemini-1.5-flash'
  }.freeze

  def initialize(api_key:, **_options)
    super
    @client = Gemini.new(
      credentials: { service: 'generative-language-api', api_key: api_key },
      options: { model: 'gemini-1.5-flash', server_sent_events: true }
    )
  end

  def chat(messages:, model:, functions: [], json_mode: true)
    gemini_model = map_model(model)

    # Convert OpenAI format to Gemini format
    contents = convert_messages(messages)
    tools = convert_functions(functions) if functions.any?

    request = {
      contents: contents,
      generationConfig: {}
    }

    request[:generationConfig][:response_mime_type] = 'application/json' if json_mode
    request[:tools] = tools if tools

    response = @client.stream_generate_content(request, model: gemini_model)
    convert_response(response)
  end

  def embedding(text:, model: nil) # rubocop:disable Lint/UnusedMethodArgument
    # Gemini uses text-embedding-004 model
    response = @client.embed_content({
                                       model: 'models/text-embedding-004',
                                       content: { parts: [{ text: text }] }
                                     })

    # Convert to OpenAI format
    {
      'data' => [
        { 'embedding' => response.dig('embedding', 'values') || [] }
      ]
    }
  end

  private

  def map_model(openai_model)
    MODELS[openai_model] || 'gemini-1.5-flash'
  end

  def convert_messages(messages)
    messages.map do |msg|
      {
        role: msg['role'] == 'assistant' ? 'model' : 'user',
        parts: [{ text: msg['content'] }]
      }
    end
  end

  def convert_functions(functions)
    [{
      function_declarations: functions.map do |func|
        {
          name: func[:function][:name],
          description: func[:function][:description],
          parameters: func[:function][:parameters]
        }
      end
    }]
  end

  def convert_response(response)
    candidate = response.dig(0, 'candidates', 0)
    return fallback_response unless candidate

    part = candidate.dig('content', 'parts', 0)
    return fallback_response unless part

    if part['functionCall']
      format_function_call(part['functionCall'])
    else
      format_text_response(part['text'])
    end
  end

  def format_function_call(function_call)
    {
      'choices' => [{
        'message' => {
          'tool_calls' => [{
            'id' => SecureRandom.uuid,
            'type' => 'function',
            'function' => {
              'name' => function_call['name'],
              'arguments' => function_call['args'].to_json
            }
          }]
        }
      }]
    }
  end

  def format_text_response(text)
    {
      'choices' => [{
        'message' => {
          'content' => text
        }
      }]
    }
  end

  def fallback_response
    {
      'choices' => [{
        'message' => {
          'content' => ''
        }
      }]
    }
  end
end
