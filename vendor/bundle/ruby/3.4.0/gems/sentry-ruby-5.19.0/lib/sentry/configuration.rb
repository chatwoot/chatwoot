# frozen_string_literal: true

require "concurrent/utility/processor_counter"

require "sentry/utils/exception_cause_chain"
require 'sentry/utils/custom_inspection'
require "sentry/dsn"
require "sentry/release_detector"
require "sentry/transport/configuration"
require "sentry/cron/configuration"
require "sentry/metrics/configuration"
require "sentry/linecache"
require "sentry/interfaces/stacktrace_builder"

module Sentry
  class Configuration
    include CustomInspection
    include LoggingHelper
    include ArgumentCheckingHelper

    # Directories to be recognized as part of your app. e.g. if you
    # have an `engines` dir at the root of your project, you may want
    # to set this to something like /(app|config|engines|lib)/
    #
    # @return [Regexp, nil]
    attr_accessor :app_dirs_pattern

    # Provide an object that responds to `call` to send events asynchronously.
    # E.g.: lambda { |event| Thread.new { Sentry.send_event(event) } }
    #
    # @deprecated It will be removed in the next major release. Please read https://github.com/getsentry/sentry-ruby/issues/1522 for more information
    # @return [Proc, nil]
    attr_reader :async

    # to send events in a non-blocking way, sentry-ruby has its own background worker
    # by default, the worker holds a thread pool that has [the number of processors] threads
    # but you can configure it with this configuration option
    # E.g.: config.background_worker_threads = 5
    #
    # if you want to send events synchronously, set the value to 0
    # E.g.: config.background_worker_threads = 0
    # @return [Integer]
    attr_accessor :background_worker_threads

    # The maximum queue size for the background worker.
    # Jobs will be rejected above this limit.
    #
    # Default is {BackgroundWorker::DEFAULT_MAX_QUEUE}.
    # @return [Integer]
    attr_accessor :background_worker_max_queue

    # a proc/lambda that takes an array of stack traces
    # it'll be used to silence (reduce) backtrace of the exception
    #
    # @example
    #   config.backtrace_cleanup_callback = lambda do |backtrace|
    #     Rails.backtrace_cleaner.clean(backtrace)
    #   end
    #
    # @return [Proc, nil]
    attr_accessor :backtrace_cleanup_callback

    # Optional Proc, called before adding the breadcrumb to the current scope
    # @example
    #   config.before = lambda do |breadcrumb, hint|
    #     breadcrumb.message = 'a'
    #     breadcrumb
    #   end
    # @return [Proc]
    attr_reader :before_breadcrumb

    # Optional Proc, called before sending an event to the server
    # @example
    #   config.before_send = lambda do |event, hint|
    #     # skip ZeroDivisionError exceptions
    #     # note: hint[:exception] would be a String if you use async callback
    #     if hint[:exception].is_a?(ZeroDivisionError)
    #       nil
    #     else
    #       event
    #     end
    #   end
    # @return [Proc]
    attr_reader :before_send

    # Optional Proc, called before sending an event to the server
    # @example
    #   config.before_send_transaction = lambda do |event, hint|
    #     # skip unimportant transactions or strip sensitive data
    #     if event.transaction == "/healthcheck/route"
    #       nil
    #     else
    #       event
    #     end
    #   end
    # @return [Proc]
    attr_reader :before_send_transaction

    # An array of breadcrumbs loggers to be used. Available options are:
    # - :sentry_logger
    # - :http_logger
    # - :redis_logger
    #
    # And if you also use sentry-rails:
    # - :active_support_logger
    # - :monotonic_active_support_logger
    #
    # @return [Array<Symbol>]
    attr_reader :breadcrumbs_logger

    # Max number of breadcrumbs a breadcrumb buffer can hold
    # @return [Integer]
    attr_accessor :max_breadcrumbs

    # Number of lines of code context to capture, or nil for none
    # @return [Integer, nil]
    attr_accessor :context_lines

    # RACK_ENV by default.
    # @return [String]
    attr_reader :environment

    # Whether the SDK should run in the debugging mode. Default is false.
    # If set to true, SDK errors will be logged with backtrace
    # @return [Boolean]
    attr_accessor :debug

    # the dsn value, whether it's set via `config.dsn=` or `ENV["SENTRY_DSN"]`
    # @return [String]
    attr_reader :dsn

    # Whitelist of enabled_environments that will send notifications to Sentry. Array of Strings.
    # @return [Array<String>]
    attr_accessor :enabled_environments

    # Logger 'progname's to exclude from breadcrumbs
    # @return [Array<String>]
    attr_accessor :exclude_loggers

    # Array of exception classes that should never be sent. See IGNORE_DEFAULT.
    # You should probably append to this rather than overwrite it.
    # @return [Array<String>]
    attr_accessor :excluded_exceptions

    # Boolean to check nested exceptions when deciding if to exclude. Defaults to true
    # @return [Boolean]
    attr_accessor :inspect_exception_causes_for_exclusion
    alias inspect_exception_causes_for_exclusion? inspect_exception_causes_for_exclusion

    # Whether to capture local variables from the raised exception's frame. Default is false.
    # @return [Boolean]
    attr_accessor :include_local_variables

    # Whether to capture events and traces into Spotlight. Default is false.
    # If you set this to true, Sentry will send events and traces to the local
    # Sidecar proxy at http://localhost:8969/stream.
    # If you want to use a different Sidecar proxy address, set this to String
    # with the proxy URL.
    # @return [Boolean, String]
    attr_accessor :spotlight

    # @deprecated Use {#include_local_variables} instead.
    alias_method :capture_exception_frame_locals, :include_local_variables

    # @deprecated Use {#include_local_variables=} instead.
    def capture_exception_frame_locals=(value)
      log_warn <<~MSG
        `capture_exception_frame_locals` is now deprecated in favor of `include_local_variables`.
      MSG

      self.include_local_variables = value
    end

    # You may provide your own LineCache for matching paths with source files.
    # This may be useful if you need to get source code from places other than the disk.
    # @see LineCache
    # @return [LineCache]
    attr_accessor :linecache

    # Logger used by Sentry. In Rails, this is the Rails logger, otherwise
    # Sentry provides its own Sentry::Logger.
    # @return [Logger]
    attr_accessor :logger

    # Project directory root for in_app detection. Could be Rails root, etc.
    # Set automatically for Rails.
    # @return [String]
    attr_accessor :project_root

    # Insert sentry-trace to outgoing requests' headers
    # @return [Boolean]
    attr_accessor :propagate_traces

    # Array of rack env parameters to be included in the event sent to sentry.
    # @return [Array<String>]
    attr_accessor :rack_env_whitelist

    # Release tag to be passed with every event sent to Sentry.
    # We automatically try to set this to a git SHA or Capistrano release.
    # @return [String]
    attr_reader :release

    # The sampling factor to apply to events. A value of 0.0 will not send
    # any events, and a value of 1.0 will send 100% of events.
    # @return [Float]
    attr_accessor :sample_rate

    # Include module versions in reports - boolean.
    # @return [Boolean]
    attr_accessor :send_modules

    # When send_default_pii's value is false (default), sensitive information like
    # - user ip
    # - user cookie
    # - request body
    # - query string
    # will not be sent to Sentry.
    # @return [Boolean]
    attr_accessor :send_default_pii

    # Allow to skip Sentry emails within rake tasks
    # @return [Boolean]
    attr_accessor :skip_rake_integration

    # IP ranges for trusted proxies that will be skipped when calculating IP address.
    attr_accessor :trusted_proxies

    # @return [String]
    attr_accessor :server_name

    # Transport related configuration.
    # @return [Transport::Configuration]
    attr_reader :transport

    # Cron related configuration.
    # @return [Cron::Configuration]
    attr_reader :cron

    # Metrics related configuration.
    # @return [Metrics::Configuration]
    attr_reader :metrics

    # Take a float between 0.0 and 1.0 as the sample rate for tracing events (transactions).
    # @return [Float, nil]
    attr_reader :traces_sample_rate

    # Take a Proc that controls the sample rate for every tracing event, e.g.
    # @example
    #   config.traces_sampler =  lambda do |tracing_context|
    #     # tracing_context[:transaction_context] contains the information about the transaction
    #     # tracing_context[:parent_sampled] contains the transaction's parent's sample decision
    #     true # return value can be a boolean or a float between 0.0 and 1.0
    #   end
    # @return [Proc]
    attr_accessor :traces_sampler

    # Easier way to use performance tracing
    # If set to true, will set traces_sample_rate to 1.0
    # @return [Boolean, nil]
    attr_reader :enable_tracing

    # Send diagnostic client reports about dropped events, true by default
    # tries to attach to an existing envelope max once every 30s
    # @return [Boolean]
    attr_accessor :send_client_reports

    # Track sessions in request/response cycles automatically
    # @return [Boolean]
    attr_accessor :auto_session_tracking

    # Whether to downsample transactions automatically because of backpressure.
    # Starts a new monitor thread to check health of the SDK every 10 seconds.
    # Default is false
    # @return [Boolean]
    attr_accessor :enable_backpressure_handling

    # Allowlist of outgoing request targets to which sentry-trace and baggage headers are attached.
    # Default is all (/.*/)
    # @return [Array<String, Regexp>]
    attr_accessor :trace_propagation_targets

    # The instrumenter to use, :sentry or :otel
    # @return [Symbol]
    attr_reader :instrumenter

    # Take a float between 0.0 and 1.0 as the sample rate for capturing profiles.
    # Note that this rate is relative to traces_sample_rate / traces_sampler,
    # i.e. the profile is sampled by this rate after the transaction is sampled.
    # @return [Float, nil]
    attr_reader :profiles_sample_rate

    # Array of patches to apply.
    # Default is {DEFAULT_PATCHES}
    # @return [Array<Symbol>]
    attr_accessor :enabled_patches

    # these are not config options
    # @!visibility private
    attr_reader :errors, :gem_specs

    # These exceptions could enter Puma's `lowlevel_error_handler` callback and the SDK's Puma integration
    # But they are mostly considered as noise and should be ignored by default
    # Please see https://github.com/getsentry/sentry-ruby/pull/2026 for more information
    PUMA_IGNORE_DEFAULT = [
      'Puma::MiniSSL::SSLError',
      'Puma::HttpParserError',
      'Puma::HttpParserError501'
    ].freeze

    # Most of these errors generate 4XX responses. In general, Sentry clients
    # only automatically report 5xx responses.
    IGNORE_DEFAULT = [
      'Mongoid::Errors::DocumentNotFound',
      'Rack::QueryParser::InvalidParameterError',
      'Rack::QueryParser::ParameterTypeError',
      'Sinatra::NotFound'
    ].freeze

    RACK_ENV_WHITELIST_DEFAULT = %w[
      REMOTE_ADDR
      SERVER_NAME
      SERVER_PORT
    ].freeze

    HEROKU_DYNO_METADATA_MESSAGE = "You are running on Heroku but haven't enabled Dyno Metadata. For Sentry's "\
    "release detection to work correctly, please run `heroku labs:enable runtime-dyno-metadata`".freeze

    LOG_PREFIX = "** [Sentry] ".freeze
    MODULE_SEPARATOR = "::".freeze
    SKIP_INSPECTION_ATTRIBUTES = [:@linecache, :@stacktrace_builder]

    INSTRUMENTERS = [:sentry, :otel]

    PROPAGATION_TARGETS_MATCH_ALL = /.*/.freeze

    DEFAULT_PATCHES = %i[redis puma http].freeze

    class << self
      # Post initialization callbacks are called at the end of initialization process
      # allowing extending the configuration of sentry-ruby by multiple extensions
      def post_initialization_callbacks
        @post_initialization_callbacks ||= []
      end

      # allow extensions to add their hooks to the Configuration class
      def add_post_initialization_callback(&block)
        post_initialization_callbacks << block
      end
    end

    def initialize
      self.app_dirs_pattern = nil
      self.debug = false
      self.background_worker_threads = (processor_count / 2.0).ceil
      self.background_worker_max_queue = BackgroundWorker::DEFAULT_MAX_QUEUE
      self.backtrace_cleanup_callback = nil
      self.max_breadcrumbs = BreadcrumbBuffer::DEFAULT_SIZE
      self.breadcrumbs_logger = []
      self.context_lines = 3
      self.include_local_variables = false
      self.environment = environment_from_env
      self.enabled_environments = []
      self.exclude_loggers = []
      self.excluded_exceptions = IGNORE_DEFAULT + PUMA_IGNORE_DEFAULT
      self.inspect_exception_causes_for_exclusion = true
      self.linecache = ::Sentry::LineCache.new
      self.logger = ::Sentry::Logger.new(STDOUT)
      self.project_root = Dir.pwd
      self.propagate_traces = true

      self.sample_rate = 1.0
      self.send_modules = true
      self.send_default_pii = false
      self.skip_rake_integration = false
      self.send_client_reports = true
      self.auto_session_tracking = true
      self.enable_backpressure_handling = false
      self.trusted_proxies = []
      self.dsn = ENV['SENTRY_DSN']
      self.spotlight = false
      self.server_name = server_name_from_env
      self.instrumenter = :sentry
      self.trace_propagation_targets = [PROPAGATION_TARGETS_MATCH_ALL]
      self.enabled_patches = DEFAULT_PATCHES.dup

      self.before_send = nil
      self.before_send_transaction = nil
      self.rack_env_whitelist = RACK_ENV_WHITELIST_DEFAULT
      self.traces_sampler = nil
      self.enable_tracing = nil

      @transport = Transport::Configuration.new
      @cron = Cron::Configuration.new
      @metrics = Metrics::Configuration.new
      @gem_specs = Hash[Gem::Specification.map { |spec| [spec.name, spec.version.to_s] }] if Gem::Specification.respond_to?(:map)

      run_post_initialization_callbacks
    end

    def dsn=(value)
      @dsn = init_dsn(value)
    end

    alias server= dsn=

    def release=(value)
      check_argument_type!(value, String, NilClass)

      @release = value
    end

    def async=(value)
      check_callable!("async", value)

      log_warn <<~MSG

        sentry-ruby now sends events asynchronously by default with its background worker (supported since 4.1.0).
        The `config.async` callback has become redundant while continuing to cause issues.
        (The problems of `async` are detailed in https://github.com/getsentry/sentry-ruby/issues/1522)

        Therefore, we encourage you to remove it and let the background worker take care of async job sending.
      It's deprecation is planned in the next major release (6.0), which is scheduled around the 3rd quarter of 2022.
      MSG

      @async = value
    end

    def breadcrumbs_logger=(logger)
      loggers =
        if logger.is_a?(Array)
          logger
        else
          Array(logger)
        end

      require "sentry/breadcrumb/sentry_logger" if loggers.include?(:sentry_logger)

      @breadcrumbs_logger = logger
    end

    def before_send=(value)
      check_callable!("before_send", value)

      @before_send = value
    end

    def before_send_transaction=(value)
      check_callable!("before_send_transaction", value)

      @before_send_transaction = value
    end

    def before_breadcrumb=(value)
      check_callable!("before_breadcrumb", value)

      @before_breadcrumb = value
    end

    def environment=(environment)
      @environment = environment.to_s
    end

    def instrumenter=(instrumenter)
      @instrumenter = INSTRUMENTERS.include?(instrumenter) ? instrumenter : :sentry
    end

    def enable_tracing=(enable_tracing)
      @enable_tracing = enable_tracing
      @traces_sample_rate ||= 1.0 if enable_tracing
    end

    def is_numeric_or_nil?(value)
      value.is_a?(Numeric) || value.nil?
    end

    def traces_sample_rate=(traces_sample_rate)
      raise ArgumentError, "traces_sample_rate must be a Numeric or nil" unless is_numeric_or_nil?(traces_sample_rate)
      @traces_sample_rate = traces_sample_rate
    end

    def profiles_sample_rate=(profiles_sample_rate)
      raise ArgumentError, "profiles_sample_rate must be a Numeric or nil" unless is_numeric_or_nil?(profiles_sample_rate)
      log_warn("Please make sure to include the 'stackprof' gem in your Gemfile to use Profiling with Sentry.") unless defined?(StackProf)
      @profiles_sample_rate = profiles_sample_rate
    end

    def sending_allowed?
      spotlight || sending_to_dsn_allowed?
    end

    def sending_to_dsn_allowed?
      @errors = []

      valid? && capture_in_environment?
    end

    def sample_allowed?
      return true if sample_rate == 1.0

      Random.rand < sample_rate
    end

    def session_tracking?
      auto_session_tracking && enabled_in_current_env?
    end

    def exception_class_allowed?(exc)
      if exc.is_a?(Sentry::Error)
        # Try to prevent error reporting loops
        log_debug("Refusing to capture Sentry error: #{exc.inspect}")
        false
      elsif excluded_exception?(exc)
        log_debug("User excluded error: #{exc.inspect}")
        false
      else
        true
      end
    end

    def enabled_in_current_env?
      enabled_environments.empty? || enabled_environments.include?(environment)
    end

    def valid_sample_rate?(sample_rate)
      return false unless sample_rate.is_a?(Numeric)
      sample_rate >= 0.0 && sample_rate <= 1.0
    end

    def tracing_enabled?
      valid_sampler = !!((valid_sample_rate?(@traces_sample_rate)) || @traces_sampler)

      (@enable_tracing != false) && valid_sampler && sending_allowed?
    end

    def profiling_enabled?
      valid_sampler = !!(valid_sample_rate?(@profiles_sample_rate))

      tracing_enabled? && valid_sampler && sending_allowed?
    end

    # @return [String, nil]
    def csp_report_uri
      if dsn && dsn.valid?
        uri = dsn.csp_report_uri
        uri += "&sentry_release=#{CGI.escape(release)}" if release && !release.empty?
        uri += "&sentry_environment=#{CGI.escape(environment)}" if environment && !environment.empty?
        uri
      end
    end

    # @api private
    def stacktrace_builder
      @stacktrace_builder ||= StacktraceBuilder.new(
        project_root: @project_root.to_s,
        app_dirs_pattern: @app_dirs_pattern,
        linecache: @linecache,
        context_lines: @context_lines,
        backtrace_cleanup_callback: @backtrace_cleanup_callback
      )
    end

    # @api private
    def detect_release
      return unless sending_allowed?

      @release ||= ReleaseDetector.detect_release(project_root: project_root, running_on_heroku: running_on_heroku?)

      if running_on_heroku? && release.nil?
        log_warn(HEROKU_DYNO_METADATA_MESSAGE)
      end
    rescue => e
      log_error("Error detecting release", e, debug: debug)
    end

    # @api private
    def error_messages
      @errors = [@errors[0]] + @errors[1..-1].map(&:downcase) # fix case of all but first
      @errors.join(", ")
    end

    private

    def init_dsn(dsn_string)
      return if dsn_string.nil? || dsn_string.empty?

      DSN.new(dsn_string)
    end

    def excluded_exception?(incoming_exception)
      excluded_exception_classes.any? do |excluded_exception|
        matches_exception?(excluded_exception, incoming_exception)
      end
    end

    def excluded_exception_classes
      @excluded_exception_classes ||= excluded_exceptions.map { |e| get_exception_class(e) }
    end

    def get_exception_class(x)
      x.is_a?(Module) ? x : safe_const_get(x)
    end

    def matches_exception?(excluded_exception_class, incoming_exception)
      if inspect_exception_causes_for_exclusion?
        Sentry::Utils::ExceptionCauseChain.exception_to_array(incoming_exception).any? { |cause| excluded_exception_class === cause }
      else
        excluded_exception_class === incoming_exception
      end
    end

    def safe_const_get(x)
      x = x.to_s unless x.is_a?(String)
      Object.const_get(x)
    rescue NameError # There's no way to safely ask if a constant exist for an unknown string
      nil
    end

    def capture_in_environment?
      return true if enabled_in_current_env?

      @errors << "Not configured to send/capture in environment '#{environment}'"
      false
    end

    def valid?
      if @dsn&.valid?
        true
      else
        @errors << "DSN not set or not valid"
        false
      end
    end

    def environment_from_env
      ENV['SENTRY_CURRENT_ENV'] || ENV['SENTRY_ENVIRONMENT'] || ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
    end

    def server_name_from_env
      if running_on_heroku?
        ENV['DYNO']
      else
        # Try to resolve the hostname to an FQDN, but fall back to whatever
        # the load name is.
        Socket.gethostname || Socket.gethostbyname(hostname).first rescue server_name
      end
    end

    def running_on_heroku?
      File.directory?("/etc/heroku") && !ENV["CI"]
    end

    def run_post_initialization_callbacks
      self.class.post_initialization_callbacks.each do |hook|
        instance_eval(&hook)
      end
    end

    def processor_count
      available_processor_count = Concurrent.available_processor_count if Concurrent.respond_to?(:available_processor_count)
      available_processor_count || Concurrent.processor_count
    end
  end
end
