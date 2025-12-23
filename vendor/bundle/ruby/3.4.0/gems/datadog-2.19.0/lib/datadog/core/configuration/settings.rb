# frozen_string_literal: true

require 'logger'

require_relative 'base'
require_relative 'ext'
require_relative '../environment/execution'
require_relative '../environment/ext'
require_relative '../runtime/ext'
require_relative '../telemetry/ext'
require_relative '../remote/ext'
require_relative '../../profiling/ext'

require_relative '../../tracing/configuration/settings'

module Datadog
  module Core
    module Configuration
      # Global configuration settings for the Datadog library.
      # @public_api
      # standard:disable Metrics/BlockLength
      class Settings
        include Base

        # @!visibility private
        def initialize(*_)
          super

          # WORKAROUND: The values for services, version, and env can get set either directly OR as a side effect of
          # accessing tags (reading or writing). This is of course really confusing and error-prone, e.g. in an app
          # WITHOUT this workaround where you define `DD_TAGS=env:envenvtag,service:envservicetag,version:envversiontag`
          # and do:
          #
          # puts Datadog.configuration.instance_exec { "#{service} #{env} #{version}" }
          # Datadog.configuration.tags
          # puts Datadog.configuration.instance_exec { "#{service} #{env} #{version}" }
          #
          # the output will be:
          #
          # [empty]
          # envservicetag envenvtag envversiontag
          #
          # That is -- the proper values for service/env/version are only set AFTER something accidentally or not triggers
          # the resolution of the tags.
          # This is really confusing, error prone, etc, so calling tags here is a really hacky but effective way to
          # avoid this. I could not think of a better way of fixing this issue without massive refactoring of tags parsing
          # (so that the individual service/env/version get correctly set even from their tags values, not as a side
          # effect). Sorry :(
          tags
        end

        # {https://docs.datadoghq.com/agent/ Datadog Agent} configuration.
        # @public_api
        settings :agent do
          # Agent hostname or IP.
          # @default `DD_AGENT_HOST` environment variable, otherwise `127.0.0.1`
          # @return [String,nil]
          option :host

          # Agent APM TCP port.
          # @see https://docs.datadoghq.com/getting_started/tracing/#datadog-apm
          # @default `DD_TRACE_AGENT_PORT` environment variable, otherwise `8126`
          # @return [String,nil]
          option :port

          # Agent APM SSL.
          # @see https://docs.datadoghq.com/getting_started/tracing/#datadog-apm
          # @default defined as part of `DD_TRACE_AGENT_URL` environment variable, otherwise `false`
          # Only applies to http connections.
          # @return [Boolean,nil]
          option :use_ssl

          # Agent APM Timeout.
          # @see https://docs.datadoghq.com/getting_started/tracing/#datadog-apm
          # @default `DD_TRACE_AGENT_TIMEOUT_SECONDS` environment variable, otherwise `30` for http, '1' for UDS
          # @return [Integer,nil]
          option :timeout_seconds

          # Agent unix domain socket path.
          # @default defined in `DD_TRACE_AGENT_URL` environment variable, otherwise '/var/run/datadog/apm.socket'
          # Agent connects via HTTP by default, but will use UDS if this is set or if unix scheme defined in
          # DD_TRACE_AGENT_URL.
          # @return [String,nil]
          option :uds_path

          # TODO: add declarative statsd configuration. Currently only usable via an environment variable.
          # Statsd configuration for agent access.
          # @public_api
          # settings :statsd do
          #   # Agent Statsd UDP port.
          #   # @configure_with {Datadog::Statsd}
          #   # @default `DD_AGENT_HOST` environment variable, otherwise `8125`
          #   # @return [String,nil]
          #   option :port
          # end
        end

        # Datadog API key.
        #
        # For internal use only.
        #
        # @default `DD_API_KEY` environment variable, otherwise `nil`
        # @return [String,nil]
        option :api_key do |o|
          o.type :string, nilable: true
          o.env Core::Environment::Ext::ENV_API_KEY
        end

        # Datadog diagnostic settings.
        #
        # Enabling these surfaces debug information that can be helpful to
        # diagnose issues related to Datadog internals.
        # @public_api
        settings :diagnostics do
          # Outputs all spans created by the host application to `Datadog.logger`.
          #
          # **This option is very verbose!** It's only recommended for non-production
          # environments.
          #
          # This option is helpful when trying to understand what information the
          # Datadog features are sending to the Agent or backend.
          # @default `DD_TRACE_DEBUG` environment variable, otherwise `false`
          # @return [Boolean]
          option :debug do |o|
            o.env [Datadog::Core::Configuration::Ext::Diagnostics::ENV_DEBUG_ENABLED,
              Datadog::Core::Configuration::Ext::Diagnostics::ENV_OTEL_LOG_LEVEL]
            o.default false
            o.type :bool
            o.env_parser do |value|
              if value
                value = value.strip.downcase
                # Debug is enabled when DD_TRACE_DEBUG is true or 1 OR
                # when OTEL_LOG_LEVEL is set to debug
                ['true', '1', 'debug'].include?(value)
              end
            end
            o.after_set do |enabled|
              # Enable rich debug print statements.
              # We do not need to unnecessarily load 'pp' unless in debugging mode.
              require 'pp' if enabled # standard:disable Lint/RedundantRequireStatement
            end
          end

          # Tracer startup debug log statement configuration.
          # @public_api
          settings :startup_logs do
            # Enable startup logs collection.
            #
            # If `nil`, defaults to logging startup logs when `datadog` detects that the application
            # is *not* running in a development environment.
            #
            # @default `DD_TRACE_STARTUP_LOGS` environment variable, otherwise `nil`
            # @return [Boolean, nil]
            option :enabled do |o|
              o.env Datadog::Core::Configuration::Ext::Diagnostics::ENV_STARTUP_LOGS_ENABLED
              # Defaults to nil as we want to know when the default value is being used
              o.type :bool, nilable: true
            end
          end
        end

        # The `env` tag in Datadog. Use it to separate out your staging, development, and production environments.
        # @see https://docs.datadoghq.com/getting_started/tagging/unified_service_tagging
        # @default `DD_ENV` environment variable, otherwise `nil`
        # @return [String,nil]
        option :env do |o|
          o.type :string, nilable: true
          # NOTE: env also gets set as a side effect of tags. See the WORKAROUND note in #initialize for details.
          o.env Core::Environment::Ext::ENV_ENVIRONMENT
        end

        # Internal {Datadog::Statsd} metrics collection.
        #
        # @public_api
        settings :health_metrics do
          # Enable health metrics collection.
          #
          # @default `DD_HEALTH_METRICS_ENABLED` environment variable, otherwise `false`
          # @return [Boolean]
          option :enabled do |o|
            o.env Datadog::Core::Configuration::Ext::Diagnostics::ENV_HEALTH_METRICS_ENABLED
            o.default false
            o.type :bool
          end

          # {Datadog::Statsd} instance to collect health metrics.
          #
          # If `nil`, health metrics creates a new {Datadog::Statsd} client with default agent configuration.
          #
          # @default `nil`
          # @return [Datadog::Statsd,nil] a custom {Datadog::Statsd} instance
          # @return [nil] an instance with default agent configuration will be lazily created
          option :statsd
        end

        # Internal `Datadog.logger` configuration.
        #
        # This logger instance is only used internally by the gem.
        # @public_api
        settings :logger do
          # The `Datadog.logger` object.
          #
          # Can be overwritten with a custom logger object that respects the
          # [built-in Ruby Logger](https://ruby-doc.org/stdlib-3.0.1/libdoc/logger/rdoc/Logger.html)
          # interface.
          #
          # @return Logger::Severity
          option :instance do |o|
            o.after_set { |value| set_option(:level, value.level) unless value.nil? }
          end

          # Log level for `Datadog.logger`.
          # @see Logger::Severity
          # @return Logger::Severity
          option :level, default: ::Logger::INFO
        end

        # Datadog Profiler-specific configurations.
        #
        # @see https://docs.datadoghq.com/tracing/profiler/
        # @public_api
        settings :profiling do
          # Enable profiling.
          #
          # @default `DD_PROFILING_ENABLED` environment variable, otherwise `false`
          # @return [Boolean]
          option :enabled do |o|
            o.env Profiling::Ext::ENV_ENABLED
            o.default false
            o.type :bool
          end

          # @public_api
          settings :exporter do
            option :transport
          end

          # Can be used to enable/disable collection of allocation profiles.
          #
          # This feature is disabled by default
          #
          # @warn Due to bugs in Ruby we only recommend enabling this feature in
          #       Ruby versions 2.x, 3.1.4+, 3.2.3+ and 3.3.0+
          #       (more details in {Datadog::Profiling::Component.enable_allocation_profiling?})
          #
          # @default `DD_PROFILING_ALLOCATION_ENABLED` environment variable as a boolean, otherwise `false`
          option :allocation_enabled do |o|
            o.type :bool
            o.env 'DD_PROFILING_ALLOCATION_ENABLED'
            o.default false
          end

          # @public_api
          settings :advanced do
            # Controls the maximum number of frames for each thread sampled. Can be tuned to avoid omitted frames in the
            # produced profiles. Increasing this may increase the overhead of profiling.
            #
            # @default `DD_PROFILING_MAX_FRAMES` environment variable, otherwise 400
            option :max_frames do |o|
              o.type :int
              o.env Profiling::Ext::ENV_MAX_FRAMES
              o.default 400
            end

            # @public_api
            settings :endpoint do
              settings :collection do
                # When using profiling together with tracing, this controls if endpoint names
                # are gathered and reported together with profiles.
                #
                # @default `DD_PROFILING_ENDPOINT_COLLECTION_ENABLED` environment variable, otherwise `true`
                # @return [Boolean]
                option :enabled do |o|
                  o.env Profiling::Ext::ENV_ENDPOINT_COLLECTION_ENABLED
                  o.default true
                  o.type :bool
                end
              end
            end

            # Can be used to disable the gathering of names and versions of gems in use by the service, used to power
            # grouping and categorization of stack traces.
            option :code_provenance_enabled do |o|
              o.type :bool
              o.default true
            end

            # Can be used to enable/disable garbage collection profiling.
            #
            # @warn To avoid https://bugs.ruby-lang.org/issues/18464 even when enabled, GC profiling is only started
            #       for Ruby versions 2.x, 3.1.4+, 3.2.3+ and 3.3.0+
            #       (more details in {Datadog::Profiling::Component.enable_gc_profiling?})
            #
            # @warn Due to a VM bug in the Ractor implementation (https://bugs.ruby-lang.org/issues/19112) this feature
            #       stops working when Ractors get garbage collected.
            #
            # @default `DD_PROFILING_GC_ENABLED` environment variable, otherwise `true`
            option :gc_enabled do |o|
              o.type :bool
              o.env 'DD_PROFILING_GC_ENABLED'
              o.default true
            end

            # Can be used to enable/disable the Datadog::Profiling.allocation_count feature.
            #
            # Requires allocation profiling to be enabled.
            #
            # @default false
            option :allocation_counting_enabled do |o|
              o.type :bool
              o.default false
            end

            # Can be used to enable/disable the collection of heap profiles.
            #
            # This feature is in preview and disabled by default. Requires Ruby 3.1+.
            #
            # @warn To enable heap profiling you are required to also enable allocation profiling.
            #
            # @default `DD_PROFILING_EXPERIMENTAL_HEAP_ENABLED` environment variable as a boolean, otherwise `false`
            option :experimental_heap_enabled do |o|
              o.type :bool
              o.env 'DD_PROFILING_EXPERIMENTAL_HEAP_ENABLED'
              o.default false
            end

            # Can be used to enable/disable the collection of heap size profiles.
            #
            # This feature is in preview and by default is enabled whenever heap profiling is enabled.
            #
            # @warn Heap size profiling depends on allocation and heap profiling, so they must be enabled as well.
            #
            # @default `DD_PROFILING_EXPERIMENTAL_HEAP_SIZE_ENABLED` environment variable as a boolean, otherwise it
            # follows the value of `experimental_heap_enabled`.
            option :experimental_heap_size_enabled do |o|
              o.type :bool
              o.env 'DD_PROFILING_EXPERIMENTAL_HEAP_SIZE_ENABLED'
              o.default true # This gets ANDed with experimental_heap_enabled in the profiler component.
            end

            # Can be used to configure the heap sampling rate: a heap sample will be collected for every x allocation
            # samples.
            #
            # The higher the value, the less accuracy in heap tracking but the smaller the overhead.
            #
            # If you needed to tweak this, please tell us why on <https://github.com/DataDog/dd-trace-rb/issues/new>,
            # so we can fix it!
            #
            # The effective heap sampling rate in terms of allocations (not allocation samples) can be calculated via
            # effective_heap_sample_rate = allocation_sample_rate * heap_sample_rate.
            #
            # @default `DD_PROFILING_EXPERIMENTAL_HEAP_SAMPLE_RATE` environment variable, otherwise `1`.
            option :experimental_heap_sample_rate do |o|
              o.type :int
              o.env 'DD_PROFILING_EXPERIMENTAL_HEAP_SAMPLE_RATE'
              o.default 1
            end

            # Can be used to disable checking which version of `libmysqlclient` is being used by the `mysql2` gem.
            #
            # This setting is only used when the `mysql2` gem is installed.
            #
            # @default `DD_PROFILING_SKIP_MYSQL2_CHECK` environment variable, otherwise `false`
            option :skip_mysql2_check do |o|
              o.type :bool
              o.env 'DD_PROFILING_SKIP_MYSQL2_CHECK'
              o.default false
            end

            # Controls data collection for the timeline feature.
            #
            # If you needed to disable this, please tell us why on <https://github.com/DataDog/dd-trace-rb/issues/new>,
            # so we can fix it!
            #
            # @default `DD_PROFILING_TIMELINE_ENABLED` environment variable as a boolean, otherwise `true`
            option :timeline_enabled do |o|
              o.type :bool
              o.env 'DD_PROFILING_TIMELINE_ENABLED'
              o.default true
            end

            # The profiler gathers data by sending `SIGPROF` unix signals to Ruby application threads.
            #
            # Sending `SIGPROF` is a common profiling approach, and may cause system calls from native
            # extensions/libraries to be interrupted with a system
            # [EINTR error code.](https://man7.org/linux/man-pages/man7/signal.7.html#:~:text=Interruption%20of%20system%20calls%20and%20library%20functions%20by%20signal%20handlers)
            # Rarely, native extensions or libraries called by them may have missing or incorrect error handling for the
            # `EINTR` error code.
            #
            # The "no signals" workaround, when enabled, enables an alternative mode for the profiler where it does not
            # send `SIGPROF` unix signals. The downside of this approach is that the profiler data will have lower
            # quality.
            #
            # This workaround is automatically enabled when gems that are known to have issues handling
            # `EINTR` error codes are detected. If you suspect you may be seeing an issue due to the profiler's use of
            # signals, you can try manually enabling this mode as a fallback.
            # Please also report these issues to us on <https://github.com/DataDog/dd-trace-rb/issues/new>, so we can
            # work with the gem authors to fix them!
            #
            # @default `DD_PROFILING_NO_SIGNALS_WORKAROUND_ENABLED` environment variable as a boolean, otherwise `:auto`
            option :no_signals_workaround_enabled do |o|
              o.env 'DD_PROFILING_NO_SIGNALS_WORKAROUND_ENABLED'
              o.default :auto
              o.env_parser do |value|
                if value
                  value = value.strip.downcase
                  ['true', '1'].include?(value)
                end
              end
            end

            # The profiler gathers data by sending `SIGPROF` unix signals to Ruby application threads.
            #
            # We've discovered that this can trigger a bug in a number of Ruby APIs in the `Dir` class, as
            # described in https://bugs.ruby-lang.org/issues/20586 .
            # This was fixed for Ruby 3.4+, and this setting is a no-op for those versions.
            #
            # @default `DD_PROFILING_DIR_INTERRUPTION_WORKAROUND_ENABLED` environment variable as a boolean,
            # otherwise `true`
            option :dir_interruption_workaround_enabled do |o|
              o.env 'DD_PROFILING_DIR_INTERRUPTION_WORKAROUND_ENABLED'
              o.type :bool
              o.default true
            end

            # Configures how much wall-time overhead the profiler targets. The profiler will dynamically adjust the
            # interval between samples it takes so as to try and maintain the property that it spends no longer than
            # this amount of wall-clock time profiling. For example, with the default value of 2%, the profiler will
            # try and cause no more than 1.2 seconds per minute of overhead. Decreasing this value will reduce the
            # accuracy of the data collected. Increasing will impact the application.
            #
            # We do not recommend tweaking this value.
            #
            # This value should be a percentage i.e. a number between 0 and 100, not 0 and 1.
            #
            # @default `DD_PROFILING_OVERHEAD_TARGET_PERCENTAGE` as a float, otherwise 2.0
            option :overhead_target_percentage do |o|
              o.type :float
              o.env 'DD_PROFILING_OVERHEAD_TARGET_PERCENTAGE'
              o.default 2.0
            end

            # Controls how often the profiler reports data, in seconds. Cannot be lower than 60 seconds.
            #
            # We do not recommend tweaking this value.
            #
            # @default `DD_PROFILING_UPLOAD_PERIOD` environment variable, otherwise 60
            option :upload_period_seconds do |o|
              o.type :int
              o.env 'DD_PROFILING_UPLOAD_PERIOD'
              o.default 60
            end

            # DEV-3.0: Remove `experimental_crash_tracking_enabled` option
            option :experimental_crash_tracking_enabled do |o|
              o.after_set do |_, _, precedence|
                unless precedence == Datadog::Core::Configuration::Option::Precedence::DEFAULT
                  Core.log_deprecation(key: :experimental_crash_tracking_enabled) do
                    'The profiling.advanced.experimental_crash_tracking_enabled setting has been deprecated for removal ' \
                    'and no longer does anything. Please remove it from your Datadog.configure block.'
                  end
                end
              end
            end

            # @deprecated Use {:gvl_enabled} instead.
            option :preview_gvl_enabled do |o|
              o.type :bool
              o.default false
              o.after_set do |_, _, precedence|
                unless precedence == Datadog::Core::Configuration::Option::Precedence::DEFAULT
                  Datadog.logger.warn(
                    'The profiling.advanced.preview_gvl_enabled setting has been deprecated for removal and ' \
                    'no longer does anything. Please remove it from your Datadog.configure block. ' \
                    'GVL profiling is now controlled by the profiling.advanced.gvl_enabled setting instead.'
                  )
                end
              end
            end

            # Controls GVL profiling. This will show when threads are waiting for GVL in the timeline view.
            #
            # This feature requires Ruby 3.2+.
            #
            # @default `DD_PROFILING_GVL_ENABLED` environment variable as a boolean, otherwise `true`
            option :gvl_enabled do |o|
              o.type :bool
              o.deprecated_env 'DD_PROFILING_PREVIEW_GVL_ENABLED'
              o.env 'DD_PROFILING_GVL_ENABLED'
              o.default true
            end

            # Controls the smallest time period the profiler will report a thread waiting for the GVL.
            #
            # The default value was set to minimize overhead. Periods smaller than the set value will not be reported (e.g.
            # the thread will be reported as whatever it was doing before it waited for the GVL).
            #
            # We do not recommend setting this to less than 1ms. Tweaking this value can increase application latency and
            # memory use.
            #
            # @default 10_000_000 (10ms)
            option :waiting_for_gvl_threshold_ns do |o|
              o.type :int
              o.default 10_000_000
            end

            # Controls if the profiler should attempt to read context from the otel library
            #
            # @default false
            option :preview_otel_context_enabled do |o|
              o.env 'DD_PROFILING_PREVIEW_OTEL_CONTEXT_ENABLED'
              o.default false
              o.env_parser do |value|
                if value
                  value = value.strip.downcase
                  if ['only', 'both'].include?(value)
                    value
                  elsif ['true', '1'].include?(value)
                    'both'
                  else
                    'false'
                  end
                end
              end
              o.setter do |value|
                if value == true
                  :both
                elsif ['only', 'both', :only, :both].include?(value)
                  value.to_sym
                else
                  false
                end
              end
            end

            # Controls if the heap profiler should attempt to clean young objects after GC, rather than just at
            # serialization time. This lowers memory usage and high percentile latency.
            #
            # Only has effect when used together with `gc_enabled: true` and `experimental_heap_enabled: true`.
            #
            # @default true
            option :heap_clean_after_gc_enabled do |o|
              o.type :bool
              o.env 'DD_PROFILING_HEAP_CLEAN_AFTER_GC_ENABLED'
              o.default true
            end

            # Controls if the profiler should use native filenames for frames in stack traces for functions implemented using
            # native code. Setting to `false` will make the profiler fall back to default Ruby stack trace behavior (only show .rb files).
            #
            # @default true
            option :native_filenames_enabled do |o|
              o.type :bool
              o.env 'DD_PROFILING_NATIVE_FILENAMES_ENABLED'
              o.default true
            end

            # Controls if the profiler should sample directly from the signal handler.
            # Sampling directly from the signal handler improves accuracy of the data collected.
            #
            # We recommend using this setting with Ruby 3.2.5+ / Ruby 3.3.4+ and above
            # as they include additional safety measures added in https://github.com/ruby/ruby/pull/11036.
            # We have not validated it thoroughly with earlier versions, but in practice it should work on Ruby 3.0+
            # (the key change was https://github.com/ruby/ruby/pull/3296).
            #
            # Enabling this on Ruby 2 is not recommended as it may cause VM crashes and/or incorrect data.
            #
            # @default true on Ruby 3.2.5+ / Ruby 3.3.4+, false on older Rubies
            option :sighandler_sampling_enabled do |o|
              o.type :bool
              o.env 'DD_PROFILING_SIGHANDLER_SAMPLING_ENABLED'
              o.default do
                Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.2.5') &&
                  !(RUBY_VERSION.start_with?('3.3.') && Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.3.4'))
              end
            end
          end

          # @public_api
          settings :upload do
            # Network timeout for reporting profiling data to Datadog.
            #
            # @default `DD_PROFILING_UPLOAD_TIMEOUT` environment variable, otherwise `30.0`
            option :timeout_seconds do |o|
              o.type :float
              o.env Profiling::Ext::ENV_UPLOAD_TIMEOUT
              o.default 30.0
            end
          end
        end

        # [Runtime Metrics](https://docs.datadoghq.com/tracing/runtime_metrics/)
        # are StatsD metrics collected by the tracer to gain additional insights into an application's performance.
        # @public_api
        settings :runtime_metrics do
          # Enable runtime metrics.
          # @default `DD_RUNTIME_METRICS_ENABLED` environment variable, otherwise `false`
          # @return [Boolean]
          option :enabled do |o|
            o.env Core::Runtime::Ext::Metrics::ENV_ENABLED
            o.default false
            o.type :bool
          end

          option :experimental_runtime_id_enabled do |o|
            o.type :bool
            o.env ['DD_TRACE_EXPERIMENTAL_RUNTIME_ID_ENABLED', 'DD_RUNTIME_METRICS_RUNTIME_ID_ENABLED']
            o.default false
          end

          option :opts, default: {}, type: :hash
          option :statsd
        end

        # The `service` tag in Datadog. Use it to group related traces into a service.
        # @see https://docs.datadoghq.com/getting_started/tagging/unified_service_tagging
        # @default `DD_SERVICE` environment variable, otherwise the program name (e.g. `'ruby'`, `'rails'`, `'pry'`)
        # @return [String]
        option :service do |o|
          o.type :string, nilable: true

          # NOTE: service also gets set as a side effect of tags. See the WORKAROUND note in #initialize for details.
          o.env [Core::Environment::Ext::ENV_SERVICE, Core::Environment::Ext::ENV_OTEL_SERVICE]
          o.default Core::Environment::Ext::FALLBACK_SERVICE_NAME

          # There's a few cases where we don't want to use the fallback service name, so this helper allows us to get a
          # nil instead so that one can do
          # nice_service_name = Datadog.configuration.service_without_fallback || nice_service_name_default
          o.helper(:service_without_fallback) do
            service_name = service
            service_name unless service_name.equal?(Core::Environment::Ext::FALLBACK_SERVICE_NAME)
          end
        end

        # The Datadog site host to send data to.
        # By default, data is sent to the Datadog US site: `app.datadoghq.com`.
        #
        # If your organization is on another site, you must update this value to the new site.
        #
        # For internal use only.
        #
        # @see https://docs.datadoghq.com/agent/troubleshooting/site/
        # @default `DD_SITE` environment variable, otherwise `nil` which sends data to `app.datadoghq.com`
        # @return [String,nil]
        option :site do |o|
          o.type :string, nilable: true
          o.env Core::Environment::Ext::ENV_SITE
        end

        # Default tags
        #
        # These tags are used by all Datadog products, when applicable.
        # e.g. trace spans, profiles, etc.
        # @default `DD_TAGS` environment variable (in the format `'tag1:value1,tag2:value2'`), otherwise `{}`
        # @return [Hash<String,String>]
        option :tags do |o|
          o.type :hash, nilable: true
          o.env [Core::Environment::Ext::ENV_TAGS, Core::Environment::Ext::ENV_OTEL_RESOURCE_ATTRIBUTES]
          o.env_parser do |env_value|
            # Parses a string containing key-value pairs and returns a hash.
            # Key-value pairs are delimited by ':' OR `=`, and pairs are separated by whitespace, comma, OR BOTH.
            result = {}
            unless env_value.nil? || env_value.empty?
              # falling back to comma as separator
              sep = env_value.include?(',') ? ',' : ' '
              # split by separator
              env_value.split(sep).each do |tag|
                tag.strip!
                next if tag.empty?

                # tag by : or = (for OpenTelemetry)
                key, val = tag.split(/[:=]/, 2).map(&:strip)
                val ||= ''
                # maps OpenTelemetry semantic attributes to Datadog tags
                key = case key.downcase
                when 'deployment.environment' then 'env'
                when 'service.version' then 'version'
                when 'service.name' then 'service'
                else key
                end
                result[key] = val unless key.empty?
              end
            end
            result
          end
          o.setter do |new_value, old_value|
            raw_tags = new_value || {}

            env_value = env
            version_value = version
            service_name = service_without_fallback

            # Override tags if defined
            raw_tags[Core::Environment::Ext::TAG_ENV] = env_value unless env_value.nil?
            raw_tags[Core::Environment::Ext::TAG_VERSION] = version_value unless version_value.nil?

            # Coerce keys to strings
            string_tags = raw_tags.collect { |k, v| [k.to_s, v] }.to_h

            # Cross-populate tag values with other settings
            if env_value.nil? && string_tags.key?(Core::Environment::Ext::TAG_ENV)
              self.env = string_tags[Core::Environment::Ext::TAG_ENV]
            end

            if version_value.nil? && string_tags.key?(Core::Environment::Ext::TAG_VERSION)
              self.version = string_tags[Core::Environment::Ext::TAG_VERSION]
            end

            if service_name.nil? && string_tags.key?(Core::Environment::Ext::TAG_SERVICE)
              self.service = string_tags[Core::Environment::Ext::TAG_SERVICE]
            end

            # Merge with previous tags
            (old_value || {}).merge(string_tags)
          end
        end

        # The time provider used by Datadog. It must respect the interface of [Time](https://ruby-doc.org/core-3.0.1/Time.html).
        #
        # When testing, it can be helpful to use a different time provider.
        #
        # For [Timecop](https://rubygems.org/gems/timecop), for example, `->{ Time.now_without_mock_time }`
        # allows Datadog features to use the real wall time when time is frozen.
        #
        # @default `->{ Time.now }`
        # @return [Proc<Time>]
        option :time_now_provider do |o|
          o.default_proc { ::Time.now }
          o.type :proc

          o.after_set do |time_provider|
            Core::Utils::Time.now_provider = time_provider
          end

          o.resetter do |_value|
            # TODO: Resetter needs access to the default value
            # TODO: to help reduce duplication.
            -> { ::Time.now }.tap do |default|
              Core::Utils::Time.now_provider = default
            end
          end
        end

        # The monotonic clock time provider used by Datadog. This option is internal and is used by `datadog-ci`
        # gem to avoid traces' durations being skewed by timecop.
        #
        # It must respect the interface of [Datadog::Core::Utils::Time#get_time] method.
        #
        # For [Timecop](https://rubygems.org/gems/timecop), for example,
        # `->(unit = :float_second) { ::Process.clock_gettime_without_mock(::Process::CLOCK_MONOTONIC, unit) }`
        # allows Datadog features to use the real monotonic time when time is frozen with
        # `Timecop.mock_process_clock = true`.
        #
        # @default `->(unit = :float_second) { ::Process.clock_gettime(::Process::CLOCK_MONOTONIC, unit)}`
        # @return [Proc<Numeric>]
        option :get_time_provider do |o|
          o.default_proc { |unit = :float_second| ::Process.clock_gettime(::Process::CLOCK_MONOTONIC, unit) }
          o.type :proc

          o.after_set do |get_time_provider|
            Core::Utils::Time.get_time_provider = get_time_provider
          end

          o.resetter do |_value|
            ->(unit = :float_second) { ::Process.clock_gettime(::Process::CLOCK_MONOTONIC, unit) }.tap do |default|
              Core::Utils::Time.get_time_provider = default
            end
          end
        end

        # The `version` tag in Datadog. Use it to enable [Deployment Tracking](https://docs.datadoghq.com/tracing/deployment_tracking/).
        # @see https://docs.datadoghq.com/getting_started/tagging/unified_service_tagging
        # @default `DD_VERSION` environment variable, otherwise `nils`
        # @return [String,nil]
        option :version do |o|
          # NOTE: version also gets set as a side effect of tags. See the WORKAROUND note in #initialize for details.
          o.type :string, nilable: true
          o.env Core::Environment::Ext::ENV_VERSION
        end

        # Client-side telemetry configuration
        # @public_api
        settings :telemetry do
          # Whether the bundled Ruby gems as reported through telemetry.
          #
          # @default `DD_TELEMETRY_DEPENDENCY_COLLECTION_ENABLED` environment variable, otherwise `true`.
          # @return [Boolean]
          option :dependency_collection do |o|
            o.type :bool
            o.env Core::Telemetry::Ext::ENV_DEPENDENCY_COLLECTION
            o.default true
          end

          # Enable telemetry collection. This allows telemetry events to be emitted to the telemetry API.
          #
          # @default `DD_INSTRUMENTATION_TELEMETRY_ENABLED` environment variable, otherwise `true`.
          #   Can be disabled as documented [here](https://docs.datadoghq.com/tracing/configure_data_security/#telemetry-collection).
          #   By default, telemetry is disabled in development environments.
          # @return [Boolean]
          option :enabled do |o|
            o.env Core::Telemetry::Ext::ENV_ENABLED
            o.default do
              if Datadog::Core::Environment::Execution.development?
                Datadog.logger.debug do
                  'Development environment detected, disabling Telemetry. ' \
                    'You can enable it with DD_INSTRUMENTATION_TELEMETRY_ENABLED=true.'
                end
                false
              else
                true
              end
            end
            o.type :bool
          end

          # Enable agentless mode for telemetry: submit telemetry events directly to the intake without Datadog Agent.
          #
          # @return [Boolean]
          # @!visibility private
          option :agentless_enabled do |o|
            o.type :bool
            o.default false
          end

          # Overrides agentless telemetry URL. To be used internally for testing purposes only.
          #
          # @return [String]
          # @!visibility private
          option :agentless_url_override do |o|
            o.type :string, nilable: true
            o.env Core::Telemetry::Ext::ENV_AGENTLESS_URL_OVERRIDE
          end

          # Enable metrics collection for telemetry. Metrics collection only works when telemetry is enabled and
          # metrics are enabled.
          # @default `DD_TELEMETRY_METRICS_ENABLED` environment variable, otherwise `true`.
          # @return [Boolean]
          option :metrics_enabled do |o|
            o.type :bool
            o.env Core::Telemetry::Ext::ENV_METRICS_ENABLED
            o.default true
          end

          # The interval in seconds when telemetry must be sent.
          #
          # This method is used internally, for testing purposes only.
          #
          # @default `DD_TELEMETRY_HEARTBEAT_INTERVAL` environment variable, otherwise `60`.
          # @return [Float]
          # @!visibility private
          option :heartbeat_interval_seconds do |o|
            o.type :float
            o.env Core::Telemetry::Ext::ENV_HEARTBEAT_INTERVAL
            o.default 60.0
          end

          # The interval in seconds when telemetry metrics are aggregated.
          # Should be a denominator of `heartbeat_interval_seconds`.
          #
          # This method is used internally, for testing purposes only.
          # @default `DD_TELEMETRY_METRICS_AGGREGATION_INTERVAL` environment variable, otherwise `10`.
          # @return [Float]
          # @!visibility private
          option :metrics_aggregation_interval_seconds do |o|
            o.type :float
            o.env Core::Telemetry::Ext::ENV_METRICS_AGGREGATION_INTERVAL
            o.default 10.0
          end

          # The install id of the application.
          #
          # This method is used internally, by library injection.
          #
          # @default `DD_INSTRUMENTATION_INSTALL_ID` environment variable, otherwise `nil`.
          # @return [String,nil]
          # @!visibility private
          option :install_id do |o|
            o.type :string, nilable: true
            o.env Core::Telemetry::Ext::ENV_INSTALL_ID
          end

          # The install type of the application.
          #
          # This method is used internally, by library injection.
          #
          # @default `DD_INSTRUMENTATION_INSTALL_TYPE` environment variable, otherwise `nil`.
          # @return [String,nil]
          # @!visibility private
          option :install_type do |o|
            o.type :string, nilable: true
            o.env Core::Telemetry::Ext::ENV_INSTALL_TYPE
          end

          # The install time of the application.
          #
          # This method is used internally, by library injection.
          #
          # @default `DD_INSTRUMENTATION_INSTALL_TIME` environment variable, otherwise `nil`.
          # @return [String,nil]
          # @!visibility private
          option :install_time do |o|
            o.type :string, nilable: true
            o.env Core::Telemetry::Ext::ENV_INSTALL_TIME
          end

          # Telemetry shutdown timeout in seconds
          #
          # @!visibility private
          option :shutdown_timeout_seconds do |o|
            o.type :float
            o.default 1.0
          end

          # Enable log collection for telemetry. Log collection only works when telemetry is enabled and
          # logs are enabled.
          # @default `DD_TELEMETRY_LOG_COLLECTION_ENABLED` environment variable, otherwise `true`.
          # @return [Boolean]
          option :log_collection_enabled do |o|
            o.type :bool
            o.env Core::Telemetry::Ext::ENV_LOG_COLLECTION
            o.default true
          end

          # For internal use only.
          # Enables telemetry debugging through the Datadog platform.
          #
          # @default `false`.
          # @return [Boolean]
          option :debug do |o|
            o.type :bool
            o.default false
          end
        end

        # Remote configuration
        # @public_api
        settings :remote do
          # Enable remote configuration. This allows fetching of remote configuration for live updates.
          #
          # @default `DD_REMOTE_CONFIGURATION_ENABLED` environment variable, otherwise `true`.
          #   By default, remote configuration is disabled in development environments.
          # @return [Boolean]
          option :enabled do |o|
            o.env Core::Remote::Ext::ENV_ENABLED
            o.default do
              if Datadog::Core::Environment::Execution.development?
                Datadog.logger.debug do
                  'Development environment detected, disabling Remote Configuration. ' \
                    'You can enable it with DD_REMOTE_CONFIGURATION_ENABLED=true.'
                end
                false
              else
                true
              end
            end
            o.type :bool
          end

          # Tune remote configuration polling interval.
          # This is a private setting. Do not use outside of Datadog. It might change at any point in time.
          #
          # @default `DD_REMOTE_CONFIG_POLL_INTERVAL_SECONDS` environment variable, otherwise `5.0` seconds.
          # @return [Float]
          # @!visibility private
          option :poll_interval_seconds do |o|
            o.env Core::Remote::Ext::ENV_POLL_INTERVAL_SECONDS
            o.type :float
            o.default 5.0
          end

          # Tune remote configuration boot timeout.
          # Early operations such as requests are blocked until RC is ready. In
          # order to not block the application indefinitely a timeout is
          # enforced allowing requests to proceed with the local configuration.
          #
          # @default `DD_REMOTE_CONFIG_BOOT_TIMEOUT` environment variable, otherwise `1.0` seconds.
          # @return [Float]
          option :boot_timeout_seconds do |o|
            o.env Core::Remote::Ext::ENV_BOOT_TIMEOUT_SECONDS
            o.type :float
            o.default 1.0
          end

          # Declare service name to bind to remote configuration. Use when
          # DD_SERVICE does not match the correct integration for which remote
          # configuration applies.
          #
          # @default `nil`.
          # @return [String,nil]
          option :service
        end

        settings :crashtracking do
          # Enables reporting of information when Ruby VM crashes.
          option :enabled do |o|
            o.type :bool
            o.default true
            o.env 'DD_CRASHTRACKING_ENABLED'
          end
        end

        # Tracer specific configuration starting with APM (e.g. DD_APM_TRACING_ENABLED).
        # @public_api
        settings :apm do
          # Tracing as a transport
          # @public_api
          settings :tracing do
            # Enables tracing as transport.
            # Disabling it will set sampling priority to -1 (FORCE_DROP) on most traces,
            # (which tells to the agent to drop these traces)
            # except heartbeat ones (1 per minute) and manually kept ones (sampling priority to 2) (e.g. appsec events)
            #
            # This is different than `DD_TRACE_ENABLED`, which completely disables tracing (sends no trace at all),
            # while this will send heartbeat traces (1 per minute) so that the service is considered alive in the backend.
            #
            # @default `DD_APM_TRACING_ENABLED` environment variable, otherwise `true`
            # @return [Boolean]
            option :enabled do |o|
              o.env Configuration::Ext::APM::ENV_TRACING_ENABLED
              o.default true
              o.type :bool
            end
          end
        end

        # TODO: Tracing should manage its own settings.
        #       Keep this extension here for now to keep things working.
        extend Datadog::Tracing::Configuration::Settings
      end
      # standard:enable Metrics/BlockLength
    end
  end
end
