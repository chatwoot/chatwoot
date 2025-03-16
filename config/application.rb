# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

## Load the specific APM agent
# We rely on DOTENV to load the environment variables
# We need these environment variables to load the specific APM agent
Dotenv::Railtie.load
require 'ddtrace' if ENV.fetch('DD_TRACE_AGENT_URL', false).present?
require 'elastic-apm' if ENV.fetch('ELASTIC_APM_SECRET_TOKEN', false).present?
require 'scout_apm' if ENV.fetch('SCOUT_KEY', false).present?

# Axiom.co integration for logging
if ENV.fetch('AXIOM_DATASET_URL', false).present? && ENV.fetch('AXIOM_API_TOKEN', false).present?
  require 'logger'
  require 'net/http'
  require 'uri'
  require 'json'

  # Custom formatter that outputs logs as JSON for Axiom
  class AxiomFormatter < Logger::Formatter
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def call(severity, time, _program_name, message)
      # Create a base log entry
      data = {
        timestamp: time.utc.iso8601,
        level: severity,
        environment: Rails.env,
        service: 'chatwoot'
      }

      # Handle different message types
      case message
      when Hash
        # If message is a hash, use its message field or stringify it
        data[:message] = message[:message] || message[:msg] || message.to_s
        # Add all other hash fields as top-level fields
        message.each do |k, v|
          next if k.to_s == 'message' || k.to_s == 'msg'

          data[k] = v unless v.nil?
        end
      when Exception
        # Format exceptions specially
        data[:message] = message.message
        data[:error_class] = message.class.name
        data[:backtrace] = message.backtrace&.join("\n") if message.backtrace
      when String
        # Simple string messages
        data[:message] = message
      else
        # Any other object type
        data[:message] = message.to_s
      end

      # Ensure message is never nil
      data[:message] ||= "Log entry at #{time.utc.iso8601}"

      # Return the formatted data
      data
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
  end

  # Custom logger that sends logs to Axiom
  class AxiomLogger < Logger
    def initialize
      super($stdout)
      self.formatter = AxiomFormatter.new
      @axiom_uri = URI.parse(ENV.fetch('AXIOM_DATASET_URL'))
      @axiom_token = ENV.fetch('AXIOM_API_TOKEN')
      @http_client = Net::HTTP.new(@axiom_uri.host, @axiom_uri.port)
      @http_client.use_ssl = @axiom_uri.scheme == 'https'
      @buffer = []
      @buffer_size = ENV.fetch('AXIOM_BUFFER_SIZE', 10).to_i
      @mutex = Mutex.new

      # Flush logs on program exit
      at_exit { flush_logs }
    end

    def add(severity, message = nil, progname = nil)
      super

      formatted_message = formatter.call(severity, Time.zone.now, progname, message || progname)

      @mutex.synchronize do
        @buffer << formatted_message
        flush_logs if @buffer.size >= @buffer_size
      end
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def flush_logs
      return if @buffer.empty?

      begin
        request = Net::HTTP::Post.new(@axiom_uri.path)
        request['Authorization'] = "Bearer #{@axiom_token}"
        request['Content-Type'] = 'application/json'

        # Sanitize the buffer to ensure all entries are valid
        sanitized_buffer = @buffer.map do |entry|
          # Ensure each entry is a hash with a message
          entry = { message: entry.to_s } unless entry.is_a?(Hash)

          # Remove any problematic values that might cause JSON serialization issues
          entry.each do |k, v|
            if v.is_a?(String) && (v.include?("\u0000") || v.include?("\u001F"))
              entry[k] = v.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
            end
          end

          entry
        end

        # Convert to JSON and send
        request.body = sanitized_buffer.to_json

        response = @http_client.request(request)

        if response.code.to_i >= 400
          $stdout.puts "Failed to send logs to Axiom: #{response.code} #{response.message}"
          $stdout.puts "Response body: #{response.body}" if response.body
          $stdout.puts "Request body sample: #{sanitized_buffer.first.inspect}" if sanitized_buffer.any?
        end
      rescue StandardError => e
        $stdout.puts "Error sending logs to Axiom: #{e.message}"
        $stdout.puts "Error backtrace: #{e.backtrace&.first(3)&.join("\n")}"
        $stdout.puts "Buffer sample: #{@buffer.first.inspect}" if @buffer.any?
      ensure
        @buffer.clear
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
  end
end

if ENV.fetch('NEW_RELIC_LICENSE_KEY', false).present?
  require 'newrelic-sidekiq-metrics'
  require 'newrelic_rpm'
end

if ENV.fetch('SENTRY_DSN', false).present?
  require 'sentry-ruby'
  require 'sentry-rails'
  require 'sentry-sidekiq'
end

module Chatwoot
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.eager_load_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('enterprise/lib')
    # rubocop:disable Rails/FilePath
    config.eager_load_paths += Dir["#{Rails.root}/enterprise/app/**"]
    # rubocop:enable Rails/FilePath

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.generators.javascripts = false
    config.generators.stylesheets = false

    # Custom chatwoot configurations
    config.x = config_for(:app).with_indifferent_access

    # Configure Axiom logging if enabled
    if ENV.fetch('AXIOM_DATASET_URL', false).present? && ENV.fetch('AXIOM_API_TOKEN', false).present?
      axiom_logger = AxiomLogger.new
      config.logger = ActiveSupport::TaggedLogging.new(axiom_logger)

      # Configure Sidekiq to use the same logger
      if defined?(Sidekiq)
        Sidekiq.configure_server do |config|
          config.logger = axiom_logger
        end
      end
    end

    # https://stackoverflow.com/questions/72970170/upgrading-to-rails-6-1-6-1-causes-psychdisallowedclass-tried-to-load-unspecif
    # https://discuss.rubyonrails.org/t/cve-2022-32224-possible-rce-escalation-bug-with-serialized-columns-in-active-record/81017
    # FIX ME : fixes breakage of installation config. we need to migrate.
    config.active_record.yaml_column_permitted_classes = [ActiveSupport::HashWithIndifferentAccess]
  end

  def self.config
    @config ||= Rails.configuration.x
  end

  def self.redis_ssl_verify_mode
    # Introduced this method to fix the issue in heroku where redis connections fail for redis 6
    # ref: https://github.com/chatwoot/chatwoot/issues/2420
    #
    # unless the redis verify mode is explicitly specified as none, we will fall back to the default 'verify peer'
    # ref: https://www.rubydoc.info/stdlib/openssl/OpenSSL/SSL/SSLContext#DEFAULT_PARAMS-constant
    ENV['REDIS_OPENSSL_VERIFY_MODE'] == 'none' ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
  end
end
