require 'openai'
require 'ruby_llm/tool'

class Llm::ResponsesClient
  DEFAULT_STORE = false
  DEFAULT_TEXT_FORMAT = { type: 'text' }.freeze
  SYSTEM_ROLES = %w[system developer].freeze

  def initialize(api_key:, api_base: nil, client: nil)
    @client = client || OpenAI::Client.new(access_token: api_key, uri_base: normalized_api_base(api_base))
  end

  def create(model:, messages:, reasoning_effort: nil, schema: nil, tools: [], metadata: {}, store: DEFAULT_STORE, **options)
    payload = build_payload(
      model: model,
      messages: messages,
      reasoning_effort: reasoning_effort,
      schema: schema,
      tools: tools,
      metadata: metadata,
      store: store,
      options: options
    )
    return payload if payload[:error]

    build_response(@client.json_post(path: '/responses', parameters: payload), request_messages: messages)
  end

  def build_payload(model:, messages:, reasoning_effort: nil, schema: nil, tools: [], metadata: {}, store: DEFAULT_STORE, options: {})
    input_messages = conversation_messages(messages)
    return no_conversation_payload(messages) if input_messages.empty?

    payload = {
      model: model,
      input: input_messages,
      store: store,
      text: { format: text_format(schema) }
    }

    instructions = instructions_from(messages)
    payload[:instructions] = instructions if instructions.present?
    payload[:reasoning] = { effort: reasoning_effort } if reasoning_effort.present?
    payload[:tools] = normalize_tools(tools) if tools.present?
    payload[:metadata] = metadata if metadata.present?

    payload.merge!(options.compact)
    payload
  end

  def self.extract_output_text(response)
    Array(response['output']).filter_map do |item|
      next unless item['type'] == 'message'

      Array(item['content']).filter_map do |content|
        content['text'] if content['type'] == 'output_text'
      end.join
    end.join
  end

  def self.extract_function_calls(response)
    Array(response['output']).filter_map do |item|
      next unless item['type'] == 'function_call'

      {
        'id' => item['id'],
        'call_id' => item['call_id'],
        'name' => item['name'],
        'arguments' => parse_arguments(item['arguments']),
        'status' => item['status']
      }
    end
  end

  def self.usage_from(response)
    usage = response['usage'] || {}
    {
      'prompt_tokens' => usage['input_tokens'],
      'completion_tokens' => usage['output_tokens'],
      'total_tokens' => usage['total_tokens'],
      'reasoning_tokens' => usage.dig('output_tokens_details', 'reasoning_tokens')
    }.compact
  end

  def self.parse_arguments(arguments)
    return arguments unless arguments.is_a?(String)

    JSON.parse(arguments)
  rescue JSON::ParserError
    arguments
  end

  private

  def build_response(response, request_messages:)
    {
      message: self.class.extract_output_text(response),
      usage: self.class.usage_from(response),
      response_id: response['id'],
      model: response['model'],
      status: response['status'],
      function_calls: self.class.extract_function_calls(response),
      raw_response: response,
      request_messages: request_messages
    }
  end

  def conversation_messages(messages)
    messages.reject { |message| SYSTEM_ROLES.include?(message[:role].to_s) }.map do |message|
      {
        role: message[:role].to_s,
        content: format_content(message[:content])
      }
    end
  end

  def instructions_from(messages)
    messages.filter_map do |message|
      message[:content] if SYSTEM_ROLES.include?(message[:role].to_s)
    end.join("\n\n")
  end

  def format_content(content)
    return content unless content.is_a?(Array)

    content.map do |part|
      normalized_part = part.deep_symbolize_keys
      case normalized_part[:type]
      when 'text'
        { type: 'input_text', text: normalized_part[:text] }
      when 'image_url'
        { type: 'input_image', image_url: normalized_part.dig(:image_url, :url) || normalized_part[:image_url] }
      else
        normalized_part
      end
    end
  end

  def text_format(schema)
    return DEFAULT_TEXT_FORMAT unless schema

    schema_payload = normalize_schema_payload(schema)
    {
      type: 'json_schema',
      name: schema_payload[:name],
      schema: schema_payload[:schema],
      strict: schema_payload[:strict]
    }
  end

  def normalize_schema_payload(schema)
    schema_instance = schema.is_a?(Class) ? schema.new : schema
    raw_schema = schema_instance.respond_to?(:to_json_schema) ? schema_instance.to_json_schema : schema_instance
    raw_schema = raw_schema.deep_symbolize_keys
    schema_def = (raw_schema[:schema] || raw_schema).deep_dup
    strict = raw_schema.key?(:strict) ? raw_schema[:strict] : schema_def.delete(:strict)

    {
      name: sanitize_schema_name(raw_schema[:name] || 'response'),
      schema: schema_def,
      strict: strict.nil? || strict
    }
  end

  def normalize_tools(tools)
    tools.map do |tool|
      if tool.is_a?(Hash)
        normalized_tool = tool.deep_symbolize_keys
        function = normalized_tool[:function]
        next normalized_tool unless function

        next {
          type: 'function',
          name: function[:name],
          description: function[:description],
          parameters: function[:parameters],
          strict: function.fetch(:strict, true)
        }.compact
      end

      tool_instance = tool.is_a?(Class) ? tool.new : tool
      {
        type: 'function',
        name: tool_instance.name,
        description: tool_instance.description,
        parameters: tool_instance.params_schema || RubyLLM::Tool::SchemaDefinition.from_parameters(tool_instance.parameters)&.json_schema,
        strict: true
      }.compact
    end
  end

  def no_conversation_payload(messages)
    {
      error: 'No conversation messages provided',
      error_code: 400,
      request_messages: messages
    }
  end

  def sanitize_schema_name(name)
    sanitized = name.to_s.gsub(/[^a-zA-Z0-9_-]/, '_')
    sanitized.presence || 'response'
  end

  def normalized_api_base(api_base)
    endpoint = api_base.presence || 'https://api.openai.com'
    endpoint = endpoint.chomp('/')
    endpoint.delete_suffix('/v1')
  end
end
