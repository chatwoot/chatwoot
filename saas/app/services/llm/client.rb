# frozen_string_literal: true

# Thin HTTP client that calls the LiteLLM proxy (OpenAI-compatible API).
# Supports both blocking and streaming (SSE) responses.
#
# Usage:
#   client = Llm::Client.new(model: 'gpt-4.1-mini')
#   response = client.chat(messages: [{ role: 'user', content: 'Hello' }])
#   # => { "id" => "...", "choices" => [...], "usage" => { ... } }
#
#   client.chat_stream(messages: [...]) do |chunk|
#     # chunk is a parsed SSE delta hash
#   end
#
# BYOK (Bring Your Own Key):
#   client = Llm::Client.new(model: 'gpt-4.1', api_key: user_provided_key)
#
module Llm
  class Client
    class RequestError < StandardError
      attr_reader :status, :body

      def initialize(message, status: nil, body: nil)
        @status = status
        @body = body
        super(message)
      end
    end

    class RateLimitError < RequestError; end
    class AuthenticationError < RequestError; end
    class TimeoutError < RequestError; end

    DEFAULT_TIMEOUT = 120
    STREAM_TIMEOUT = 300

    attr_reader :model, :base_url, :api_key, :timeout

    def initialize(model: nil, api_key: nil, base_url: nil, timeout: nil)
      @model = (model || LlmConstants::DEFAULT_MODEL).sub(%r{^litellm/}, '')
      @base_url = base_url || litellm_base_url
      @api_key = api_key || litellm_api_key
      @timeout = timeout || DEFAULT_TIMEOUT
    end

    # Blocking chat completion
    # Returns parsed JSON response hash
    def chat(messages:, **options)
      payload = build_payload(messages: messages, stream: false, **options)
      response = post('/v1/chat/completions', payload)
      parse_response(response)
    end

    # Streaming chat completion via SSE
    # Yields parsed chunk hashes as they arrive
    def chat_stream(messages:, **options, &block)
      payload = build_payload(messages: messages, stream: true, **options)
      stream_post('/v1/chat/completions', payload, &block)
    end

    # Embeddings endpoint
    def embed(input:, model: nil)
      payload = {
        model: model || LlmConstants::DEFAULT_EMBEDDING_MODEL,
        input: input
      }
      response = post('/v1/embeddings', payload)
      parse_response(response)
    end

    # Health check — pings the LiteLLM proxy
    def healthy?
      uri = URI.parse("#{base_url}/health")
      http = build_http(uri)
      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{api_key}" if api_key.present?
      response = http.request(request)
      response.is_a?(Net::HTTPSuccess)
    rescue StandardError
      false
    end

    # List available models from the proxy
    def models
      uri = URI.parse("#{base_url}/v1/models")
      http = build_http(uri)
      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{api_key}" if api_key.present?
      response = http.request(request)
      JSON.parse(response.body)
    rescue StandardError => e
      Rails.logger.error("[Llm::Client] Failed to list models: #{e.message}")
      { 'data' => [] }
    end

    private

    def build_payload(messages:, stream: false, **options)
      {
        model: model,
        messages: messages,
        stream: stream,
        temperature: options[:temperature],
        max_tokens: options[:max_tokens],
        top_p: options[:top_p],
        tools: options[:tools],
        tool_choice: options[:tool_choice]
      }.compact
    end

    def post(path, payload)
      uri = URI.parse("#{base_url}#{path}")
      http = build_http(uri)

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request['Authorization'] = "Bearer #{api_key}" if api_key.present?
      request.body = payload.to_json

      response = http.request(request)
      handle_errors(response)
      response
    end

    def stream_post(path, payload, &block)
      uri = URI.parse("#{base_url}#{path}")
      http = build_http(uri, timeout: STREAM_TIMEOUT)

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request['Authorization'] = "Bearer #{api_key}" if api_key.present?
      request.body = payload.to_json

      http.request(request) do |response|
        handle_errors(response)
        parse_sse_stream(response, &block)
      end
    end

    def parse_sse_stream(response)
      buffer = +''
      response.read_body do |chunk|
        buffer << chunk
        while (line_end = buffer.index("\n"))
          line = buffer.slice!(0..line_end).strip
          next if line.empty?
          next unless line.start_with?('data: ')

          data = line.sub('data: ', '')
          break if data == '[DONE]'

          parsed = JSON.parse(data)
          yield parsed
        end
      end
    end

    def parse_response(response)
      JSON.parse(response.body)
    end

    def handle_errors(response)
      return if response.is_a?(Net::HTTPSuccess)

      body = begin
        JSON.parse(response.body)
      rescue StandardError
        response.body
      end
      message = body.is_a?(Hash) ? body.dig('error', 'message') || body['detail'] || response.message : response.message

      case response.code.to_i
      when 401
        raise AuthenticationError.new("Authentication failed: #{message}", status: 401, body: body)
      when 429
        raise RateLimitError.new("Rate limited: #{message}", status: 429, body: body)
      when 408, 504
        raise TimeoutError.new("Request timed out: #{message}", status: response.code.to_i, body: body)
      else
        raise RequestError.new("LLM request failed (#{response.code}): #{message}", status: response.code.to_i, body: body)
      end
    end

    def build_http(uri, timeout: nil)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = 10
      http.read_timeout = timeout || @timeout
      http.write_timeout = 30
      http
    end

    def litellm_base_url
      ENV.fetch('LITELLM_BASE_URL', 'http://localhost:4000')
    end

    def litellm_api_key
      ENV.fetch('LITELLM_API_KEY', nil)
    end
  end
end
