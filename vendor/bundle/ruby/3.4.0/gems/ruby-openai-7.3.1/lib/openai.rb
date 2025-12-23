require "faraday"
require "faraday/multipart"

require_relative "openai/http"
require_relative "openai/client"
require_relative "openai/files"
require_relative "openai/finetunes"
require_relative "openai/images"
require_relative "openai/models"
require_relative "openai/assistants"
require_relative "openai/threads"
require_relative "openai/messages"
require_relative "openai/runs"
require_relative "openai/run_steps"
require_relative "openai/vector_stores"
require_relative "openai/vector_store_files"
require_relative "openai/vector_store_file_batches"
require_relative "openai/audio"
require_relative "openai/version"
require_relative "openai/batches"

module OpenAI
  class Error < StandardError; end
  class ConfigurationError < Error; end

  class MiddlewareErrors < Faraday::Middleware
    def call(env)
      @app.call(env)
    rescue Faraday::Error => e
      raise e unless e.response.is_a?(Hash)

      logger = Logger.new($stdout)
      logger.formatter = proc do |_severity, _datetime, _progname, msg|
        "\033[31mOpenAI HTTP Error (spotted in ruby-openai #{VERSION}): #{msg}\n\033[0m"
      end
      logger.error(e.response[:body])

      raise e
    end
  end

  class Configuration
    attr_accessor :access_token,
                  :api_type,
                  :api_version,
                  :log_errors,
                  :organization_id,
                  :uri_base,
                  :request_timeout,
                  :extra_headers

    DEFAULT_API_VERSION = "v1".freeze
    DEFAULT_URI_BASE = "https://api.openai.com/".freeze
    DEFAULT_REQUEST_TIMEOUT = 120
    DEFAULT_LOG_ERRORS = false

    def initialize
      @access_token = nil
      @api_type = nil
      @api_version = DEFAULT_API_VERSION
      @log_errors = DEFAULT_LOG_ERRORS
      @organization_id = nil
      @uri_base = DEFAULT_URI_BASE
      @request_timeout = DEFAULT_REQUEST_TIMEOUT
      @extra_headers = {}
    end
  end

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= OpenAI::Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  # Estimate the number of tokens in a string, using the rules of thumb from OpenAI:
  # https://help.openai.com/en/articles/4936856-what-are-tokens-and-how-to-count-them
  def self.rough_token_count(content = "")
    raise ArgumentError, "rough_token_count requires a string" unless content.is_a? String
    return 0 if content.empty?

    count_by_chars = content.size / 4.0
    count_by_words = content.split.size * 4.0 / 3
    estimate = ((count_by_chars + count_by_words) / 2.0).round
    [1, estimate].max
  end
end
