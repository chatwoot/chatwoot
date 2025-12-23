# frozen_string_literal: true

module RubyLLM
  # Connection class for managing API connections to various providers.
  class Connection
    attr_reader :provider, :connection, :config

    def self.basic(&)
      Faraday.new do |f|
        f.response :logger,
                   RubyLLM.logger,
                   bodies: false,
                   response: false,
                   errors: true,
                   headers: false,
                   log_level: :debug
        f.response :raise_error
        yield f if block_given?
      end
    end

    def initialize(provider, config)
      @provider = provider
      @config = config

      ensure_configured!
      @connection ||= Faraday.new(provider.api_base) do |faraday|
        setup_timeout(faraday)
        setup_logging(faraday)
        setup_retry(faraday)
        setup_middleware(faraday)
        setup_http_proxy(faraday)
      end
    end

    def post(url, payload, &)
      body = payload.is_a?(Hash) ? JSON.generate(payload, ascii_only: false) : payload
      @connection.post url, body do |req|
        req.headers.merge! @provider.headers if @provider.respond_to?(:headers)
        yield req if block_given?
      end
    end

    def get(url, &)
      @connection.get url do |req|
        req.headers.merge! @provider.headers if @provider.respond_to?(:headers)
        yield req if block_given?
      end
    end

    def instance_variables
      super - %i[@config @connection]
    end

    private

    def setup_timeout(faraday)
      faraday.options.timeout = @config.request_timeout
    end

    def setup_logging(faraday)
      faraday.response :logger,
                       RubyLLM.logger,
                       bodies: true,
                       response: true,
                       errors: true,
                       headers: false,
                       log_level: :debug do |logger|
        logger.filter(%r{[A-Za-z0-9+/=]{100,}}, 'data":"[BASE64 DATA]"')
        logger.filter(/[-\d.e,\s]{100,}/, '[EMBEDDINGS ARRAY]')
      end
    end

    def setup_retry(faraday)
      faraday.request :retry, {
        max: @config.max_retries,
        interval: @config.retry_interval,
        interval_randomness: @config.retry_interval_randomness,
        backoff_factor: @config.retry_backoff_factor,
        exceptions: retry_exceptions,
        retry_statuses: [429, 500, 502, 503, 504, 529]
      }
    end

    def setup_middleware(faraday)
      faraday.request :json
      faraday.response :json
      faraday.adapter :net_http
      faraday.use :llm_errors, provider: @provider
    end

    def setup_http_proxy(faraday)
      return unless @config.http_proxy

      faraday.proxy = @config.http_proxy
    end

    def retry_exceptions
      [
        Errno::ETIMEDOUT,
        Timeout::Error,
        Faraday::TimeoutError,
        Faraday::ConnectionFailed,
        Faraday::RetriableResponse,
        RubyLLM::RateLimitError,
        RubyLLM::ServerError,
        RubyLLM::ServiceUnavailableError,
        RubyLLM::OverloadedError
      ]
    end

    def ensure_configured!
      return if @provider.configured?

      missing = @provider.configuration_requirements.reject { |req| @config.send(req) }
      config_block = <<~RUBY
        RubyLLM.configure do |config|
          #{missing.map { |key| "config.#{key} = ENV['#{key.to_s.upcase}']" }.join("\n  ")}
        end
      RUBY

      raise ConfigurationError,
            "#{@provider.name} provider is not configured. Add this to your initialization:\n\n#{config_block}"
    end
  end
end
