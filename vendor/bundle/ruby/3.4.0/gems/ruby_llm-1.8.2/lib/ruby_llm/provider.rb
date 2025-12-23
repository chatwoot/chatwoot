# frozen_string_literal: true

module RubyLLM
  # Base class for LLM providers.
  class Provider
    include Streaming

    attr_reader :config, :connection

    def initialize(config)
      @config = config
      ensure_configured!
      @connection = Connection.new(self, @config)
    end

    def api_base
      raise NotImplementedError
    end

    def headers
      {}
    end

    def slug
      self.class.slug
    end

    def name
      self.class.name
    end

    def capabilities
      self.class.capabilities
    end

    def configuration_requirements
      self.class.configuration_requirements
    end

    def complete(messages, tools:, temperature:, model:, params: {}, headers: {}, schema: nil, &) # rubocop:disable Metrics/ParameterLists
      normalized_temperature = maybe_normalize_temperature(temperature, model)

      payload = Utils.deep_merge(
        render_payload(
          messages,
          tools: tools,
          temperature: normalized_temperature,
          model: model,
          stream: block_given?,
          schema: schema
        ),
        params
      )

      if block_given?
        stream_response @connection, payload, headers, &
      else
        sync_response @connection, payload, headers
      end
    end

    def list_models
      response = @connection.get models_url
      parse_list_models_response response, slug, capabilities
    end

    def embed(text, model:, dimensions:)
      payload = render_embedding_payload(text, model:, dimensions:)
      response = @connection.post(embedding_url(model:), payload)
      parse_embedding_response(response, model:, text:)
    end

    def moderate(input, model:)
      payload = render_moderation_payload(input, model:)
      response = @connection.post moderation_url, payload
      parse_moderation_response(response, model:)
    end

    def paint(prompt, model:, size:)
      payload = render_image_payload(prompt, model:, size:)
      response = @connection.post images_url, payload
      parse_image_response(response, model:)
    end

    def configured?
      configuration_requirements.all? { |req| @config.send(req) }
    end

    def local?
      self.class.local?
    end

    def remote?
      self.class.remote?
    end

    def parse_error(response)
      return if response.body.empty?

      body = try_parse_json(response.body)
      case body
      when Hash
        body.dig('error', 'message')
      when Array
        body.map do |part|
          part.dig('error', 'message')
        end.join('. ')
      else
        body
      end
    end

    def format_messages(messages)
      messages.map do |msg|
        {
          role: msg.role.to_s,
          content: msg.content
        }
      end
    end

    def format_tool_calls(_tool_calls)
      nil
    end

    def parse_tool_calls(_tool_calls)
      nil
    end

    class << self
      def name
        to_s.split('::').last
      end

      def slug
        name.downcase
      end

      def capabilities
        raise NotImplementedError
      end

      def configuration_requirements
        []
      end

      def local?
        false
      end

      def remote?
        !local?
      end

      def configured?(config)
        configuration_requirements.all? { |req| config.send(req) }
      end

      def register(name, provider_class)
        providers[name.to_sym] = provider_class
      end

      def for(model)
        model_info = Models.find(model)
        providers[model_info.provider.to_sym]
      end

      def providers
        @providers ||= {}
      end

      def local_providers
        providers.select { |_slug, provider_class| provider_class.local? }
      end

      def remote_providers
        providers.select { |_slug, provider_class| provider_class.remote? }
      end

      def configured_providers(config)
        providers.select do |_slug, provider_class|
          provider_class.configured?(config)
        end.values
      end

      def configured_remote_providers(config)
        providers.select do |_slug, provider_class|
          provider_class.remote? && provider_class.configured?(config)
        end.values
      end
    end

    private

    def try_parse_json(maybe_json)
      return maybe_json unless maybe_json.is_a?(String)

      JSON.parse(maybe_json)
    rescue JSON::ParserError
      maybe_json
    end

    def ensure_configured!
      missing = configuration_requirements.reject { |req| @config.send(req) }
      return if missing.empty?

      raise ConfigurationError, "Missing configuration for #{name}: #{missing.join(', ')}"
    end

    def maybe_normalize_temperature(temperature, _model)
      temperature
    end

    def sync_response(connection, payload, additional_headers = {})
      response = connection.post completion_url, payload do |req|
        req.headers = additional_headers.merge(req.headers) unless additional_headers.empty?
      end
      parse_completion_response response
    end
  end
end
