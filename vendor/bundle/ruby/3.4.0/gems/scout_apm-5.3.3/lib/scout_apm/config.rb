require 'yaml'
require 'erb'

require 'scout_apm/environment'

# Valid Config Options:
#
# This list is complete, but some are old and unused, or for developers of
# scout_apm itself. See the documentation at https://docs.scoutapm.com for
# customer-focused documentation.
#
# application_root - override the detected directory of the application
# collect_remote_ip - automatically capture user's IP into a Trace's Context
# compress_payload - true/false to enable gzipping of payload
# data_file        - override the default temporary storage location. Must be a location in a writable directory
# dev_trace        - true or false. Enables always-on tracing in development environmen only
# direct_host      - override the default "direct" host. The direct_host bypasses the ingestion pipeline and goes directly to the webserver, and is primarily used for features under development.
# enable_background_jobs - true or false
# host             - configuration used in development
# hostname         - override the default hostname detection. Default varies by environment - either system hostname, or PAAS hostname
# key              - the account key with Scout APM. Found in Settings in the Web UI
# log_file_path    - either a directory or "STDOUT".
# log_level        - DEBUG / INFO / WARN as usual
# max_traces       - Internal: An experiment in trace quality, this requires a server-side setting as well. Setting this to a higher value will make your app server work harder for no benefit.
# monitor          - true or false.  False prevents any instrumentation from starting
# name             - override the name reported to APM. This is the name that shows in the Web UI
# profile          - turn on/off scoutprof (only applicable in Gem versions including scoutprof)
# proxy            - an http proxy
# report_format    - 'json' or 'marshal'. Marshal is legacy and will be removed.
# scm_subdirectory - if the app root lives in source management in a subdirectory. E.g. #{SCM_ROOT}/src
# uri_reporting    - 'path' or 'full_path' default is 'full_path', which reports URL params as well as the path.
# record_queue_time - true/false to enable recording of queuetime.
# remote_agent_host - Internal: What host to bind to, and also send messages to for remote. Default: 127.0.0.1.
# remote_agent_port - What port to bind the remote webserver to
# start_resque_server_instrument - Used in special situations with certain Resque installs
# timeline_traces - true/false to enable sending of of the timeline trace format.
# auto_instruments - true/false whether to install autoinstruments. Only installed if on a supported Ruby version.
# auto_instruments_ignore  - An array of file names to exclude from autoinstruments (Ex: ['application_controller']).
# use_prepend              - Whether to apply instrumentation using Module#Prepend instead
#                            of Module#alias_method (Default: false)
# alias_method_instruments - If `use_prepend` is true, continue to use Module#alias_method for
#                            any instruments listed in this array. Default: []
# prepend_instruments      - If `use_prepend` is false, force using Module#prepend for any
#                            instruments listed in this array. Default: []
#
# Any of these config settings can be set with an environment variable prefixed
# by SCOUT_ and uppercasing the key: SCOUT_LOG_LEVEL for instance.

module ScoutApm
  class Config
    KNOWN_CONFIG_OPTIONS = [
        'application_root',
        'async_recording',
        'collect_remote_ip',
        'compress_payload',
        'config_file',
        'data_file',
        'database_metric_limit',
        'database_metric_report_limit',
        'detailed_middleware',
        'dev_trace',
        'direct_host',
        'disabled_instruments',
        'enable_background_jobs',
        'external_service_metric_limit',
        'external_service_metric_report_limit',
        'host',
        'hostname',
        'ignore',
        'key',
        'log_class',
        'log_file_path',
        'log_level',
        'log_stderr',
        'log_stdout',
        'max_traces',
        'monitor',
        'name',
        'profile',
        'proxy',
        'record_queue_time',
        'remote_agent_host',
        'remote_agent_port',
        'report_format',
        'revision_sha',
        'scm_subdirectory',
        'start_resque_server_instrument',
        'ssl_cert_file',
        'uri_reporting',
        'instrument_http_url_length',
        'timeline_traces',
        'auto_instruments',
        'auto_instruments_ignore',
        'use_prepend',
        'alias_method_instruments',
        'prepend_instruments',

        # Error Service Related Configuration
        'errors_enabled',
        'errors_ignored_exceptions',
        'errors_filtered_params',
        'errors_host',
    ]

    ################################################################################
    # Coersions
    #
    # Since we get values from environment variables, which are always strings,
    # we need to be able to coerce them into the correct data type.  For
    # instance, setting "SCOUT_ENABLE=false" should be interpreted as being the
    # boolean false, not a string that is present & true.
    #
    # Similarly, this will help parsing YAML configurations if the user has a
    # key like:
    #   monitor: "false"
    ################################################################################

    # Any boolean is passed through
    # A string is false iff it is 0 length, is "f", or "false" - otherwise true
    # An number is false if it is exactly 0
    # Other types are false
    class BooleanCoercion
      def coerce(val)
        case val
        when NilClass
          false
        when TrueClass
          val
        when FalseClass
          val
        when String
          coerce_string(val)
        when Numeric
          val != 0
        else
          false
        end
      end

      def coerce_string(val)
        val = val.downcase.strip
        return false if val.length == 0
        return false if val == "f"
        return false if val == "false"

        true
      end
    end

    # If the passed value is a string, attempt to decode as json
    # This is a no-op unless the `JSON` constant is defined
    class JsonCoercion
      def coerce(val)
        case val
        when String
          if defined?(JSON) && JSON.respond_to?(:parse)
            JSON.parse(val)
          else
            val
          end
        else
          val
        end
      end
    end

    class IntegerCoercion
      def coerce(val)
        val.to_i
      end
    end

    # Simply returns the passed in value, without change
    class NullCoercion
      def coerce(val)
        val
      end
    end


    SETTING_COERCIONS = {
      'async_recording' => BooleanCoercion.new,
      'detailed_middleware' => BooleanCoercion.new,
      'dev_trace' => BooleanCoercion.new,
      'enable_background_jobs' => BooleanCoercion.new,
      'ignore' => JsonCoercion.new,
      'max_traces' => IntegerCoercion.new,
      'monitor' => BooleanCoercion.new,
      'collect_remote_ip' => BooleanCoercion.new,
      'compress_payload' => BooleanCoercion.new,
      'database_metric_limit'  => IntegerCoercion.new,
      'database_metric_report_limit' => IntegerCoercion.new,
      'external_service_metric_limit'  => IntegerCoercion.new,
      'external_service_metric_report_limit' => IntegerCoercion.new,
      'instrument_http_url_length' => IntegerCoercion.new,
      'record_queue_time' => BooleanCoercion.new,
      'start_resque_server_instrument' => BooleanCoercion.new,
      'timeline_traces' => BooleanCoercion.new,
      'auto_instruments' => BooleanCoercion.new,
      'auto_instruments_ignore' => JsonCoercion.new,
      'use_prepend' => BooleanCoercion.new,
      'alias_method_instruments' => JsonCoercion.new,
      'prepend_instruments' => JsonCoercion.new,
      'errors_enabled' => BooleanCoercion.new,
      'errors_ignored_exceptions' => JsonCoercion.new,
      'errors_filtered_params' => JsonCoercion.new,
    }


    ################################################################################
    # Configuration layers & reading
    ################################################################################

    # Load up a config instance without attempting to load a file.
    # Useful for bootstrapping.
    def self.without_file(context)
      overlays = [
        ConfigEnvironment.new,
        ConfigDefaults.new,
        ConfigNull.new,
      ]
      new(context, overlays)
    end

    # Load up a config instance, attempting to load a yaml file.  Allows a
    # definite location if requested, or will attempt to load the default
    # configuration file: APP_ROOT/config/scout_apm.yml
    def self.with_file(context, file_path=nil, config={})
      overlays = [
        ConfigEnvironment.new,
        ConfigFile.new(context, file_path, config),
        ConfigDefaults.new,
        ConfigNull.new,
      ]
      new(context, overlays)
    end

    def initialize(context, overlays)
      @context = context
      @overlays = Array(overlays)
    end

    # For a given key, what is the first overlay says that it can handle it?
    def overlay_for_key(key)
      @overlays.detect{ |overlay| overlay.has_key?(key) }
    end

    def value(key)
      if ! KNOWN_CONFIG_OPTIONS.include?(key)
        logger.debug("Requested looking up a unknown configuration key: #{key} (not a problem. Evaluate and add to config.rb)")
      end

      o = overlay_for_key(key)
      raw_value = if o
                    o.value(key)
                  else
                    # No overlay said it could handle this key, bail out with nil.
                    nil
                  end

      coercion = SETTING_COERCIONS.fetch(key, NullCoercion.new)
      coercion.coerce(raw_value)
    end

    # Did we load anything for configuration?
    def any_keys_found?
      @overlays.any? { |overlay| overlay.any_keys_found? }
    end

    # Returns an array of config keys, values, and source
    # {key: "monitor", value: "true", source: "environment"}
    #
    def all_settings
      KNOWN_CONFIG_OPTIONS.inject([]) do |memo, key|
        o = overlay_for_key(key)
        memo << {:key => key, :value => value(key).inspect, :source => o.name}
      end
    end

    def log_settings(logger)
      logger.debug(
        "Resolved Setting Values:\n" +
        all_settings.map{|hsh| "#{hsh[:source]} - #{hsh[:key]}: #{hsh[:value]}"}.join("\n")
      )
    end

    def logger
      @context.logger
    end

    class ConfigDefaults
      DEFAULTS = {
        'compress_payload'       => true,
        'detailed_middleware'    => false,
        'dev_trace'              => false,
        'direct_host'            => 'https://apm.scoutapp.com',
        'disabled_instruments'   => [],
        'enable_background_jobs' => true,
        'host'                   => 'https://checkin.scoutapp.com',
        'ignore'                 => [],
        'log_level'              => 'info',
        'max_traces'             => 10,
        'profile'                => true, # for scoutprof
        'report_format'          => 'json',
        'scm_subdirectory'       => '',
        'uri_reporting'          => 'full_path',
        'remote_agent_host'      => '127.0.0.1',
        'remote_agent_port'      => 7721, # picked at random
        'database_metric_limit'  => 5000, # The hard limit on db metrics
        'database_metric_report_limit' => 1000,
        'external_service_metric_limit'  => 5000, # The hard limit on external service metrics
        'external_service_metric_report_limit' => 1000,
        'instrument_http_url_length' => 300,
        'start_resque_server_instrument' => true, # still only starts if Resque is detected
        'collect_remote_ip' => true,
        'record_queue_time' => true,
        'timeline_traces' => true,
        'auto_instruments' => false,
        'auto_instruments_ignore' => [],
        'use_prepend' => false,
        'alias_method_instruments' => [],
        'prepend_instruments' => [],
        'ssl_cert_file' => File.join( File.dirname(__FILE__), *%w[.. .. data cacert.pem] ),
        'errors_enabled' => false,
        'errors_ignored_exceptions' => %w(ActiveRecord::RecordNotFound ActionController::RoutingError),
        'errors_filtered_params' => %w(password s3-key),
        'errors_host' => 'https://errors.scoutapm.com',
      }.freeze

      def value(key)
        DEFAULTS[key]
      end

      def has_key?(key)
        DEFAULTS.has_key?(key)
      end

      # Defaults are here, but not counted as user specified.
      def any_keys_found?
        false
      end

      def name
        "defaults"
      end
    end


    # Good News: It has every config value you could want
    # Bad News: The content of that config value is always nil
    # Used for the null-object pattern
    class ConfigNull
      def value(*)
        nil
      end

      def has_key?(*)
        true
      end

      def any_keys_found?
        false
      end

      def name
        "no-config"
      end
    end

    class ConfigEnvironment
      def value(key)
        val = ENV[key_to_env_key(key)]
        val.to_s.strip.length.zero? ? nil : val
      end

      def has_key?(key)
        ENV.has_key?(key_to_env_key(key))
      end

      def key_to_env_key(key)
        'SCOUT_' + key.upcase
      end

      def any_keys_found?
        KNOWN_CONFIG_OPTIONS.any? { |option|
          ENV.has_key?(key_to_env_key(option))
        }
      end

      def name
        "environment"
      end
    end

    # Attempts to load a configuration file, and parse it as YAML. If the file
    # is not found, inaccessbile, or unparsable, log a message to that effect,
    # and move on.
    class ConfigFile
      def initialize(context, file_path=nil, config={})
        @context = context
        @config = config || {}
        @resolved_file_path = file_path || determine_file_path
        load_file(@resolved_file_path)
      end

      def value(key)
        if @file_loaded
          val = @settings[key]
          val.to_s.strip.length.zero? ? nil : val
        else
          nil
        end
      end

      def has_key?(key)
        @settings.has_key?(key)
      end

      def any_keys_found?
        KNOWN_CONFIG_OPTIONS.any? { |option|
          @settings.has_key?(option)
        }
      end

      def name
        "config-file"
      end

      private

      attr_reader :context

      def load_file(file)
        @settings = {}
        if !File.exist?(@resolved_file_path)
          logger.debug("Configuration file #{file} does not exist, skipping.")
          @file_loaded = false
          return
        end

        if !app_environment
          logger.debug("Could not determine application environment, aborting configuration file load")
          @file_loaded = false
          return
        end

        begin
          raw_file = File.read(@resolved_file_path)
          erb_file = ERB.new(raw_file).result(binding)
          parsed_yaml = YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(erb_file) : YAML.load(erb_file)
          file_settings = parsed_yaml[app_environment]

          if file_settings.is_a? Hash
            logger.debug("Loaded Configuration: #{@resolved_file_path}. Using environment: #{app_environment}")
            @settings = file_settings
            @file_loaded = true
          else
            logger.info("Couldn't find configuration in #{@resolved_file_path} for environment: #{app_environment}. Configuration in ENV will still be applied.")
            @file_loaded = false
          end
        rescue ScoutApm::AllExceptionsExceptOnesWeMustNotRescue => e # Everything except the most important exceptions we should never interfere with
          logger.info("Failed loading configuration file (#{@resolved_file_path}): ScoutAPM will continue starting with configuration from ENV and defaults. Exception was #{e.class}: #{e.message}#{e.backtrace.map { |bt| "\n  #{bt}" }.join('')}")
          @file_loaded = false
        end
      end

      def determine_file_path
        File.join(context.environment.root, "config", "scout_apm.yml")
      end

      def app_environment
        @config[:environment] || context.environment.env
      end

      def logger
        context.logger
      end
    end
  end
end
