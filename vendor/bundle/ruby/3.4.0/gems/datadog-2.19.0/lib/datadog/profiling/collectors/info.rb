# frozen_string_literal: true

require "set"
require "time"
require "libdatadog"

module Datadog
  module Profiling
    module Collectors
      # Collects information of relevance for profiler. This will get sent alongside
      # the profile and show up in the UI or potentially influence processing in some way.
      #
      # Information is currently collected and frozen at construction time. A full collector
      # could be seen as overkill for this case but it allows us to centralize information
      # gathering and easily support more flexible/dynamic info collection in the future.
      class Info
        def initialize(settings)
          @profiler_info = nil
          @info = {
            platform: collect_platform_info,
            runtime: collect_runtime_info,
            application: collect_application_info(settings),
            profiler: collect_profiler_info(settings),
          }.freeze
        end

        attr_reader :info

        private

        # Ruby GC tuning environment variables
        RUBY_GC_TUNING_ENV_VARS = [
          "RUBY_GC_HEAP_FREE_SLOTS",
          "RUBY_GC_HEAP_GROWTH_FACTOR",
          "RUBY_GC_HEAP_GROWTH_MAX_SLOTS",
          "RUBY_GC_HEAP_FREE_SLOTS_MIN_RATIO",
          "RUBY_GC_HEAP_FREE_SLOTS_MAX_RATIO",
          "RUBY_GC_HEAP_FREE_SLOTS_GOAL_RATIO",
          "RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR",
          "RUBY_GC_HEAP_REMEMBERED_WB_UNPROTECTED_OBJECTS_LIMIT_RATIO",
          "RUBY_GC_MALLOC_LIMIT",
          "RUBY_GC_MALLOC_LIMIT_MAX",
          "RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR",
          "RUBY_GC_OLDMALLOC_LIMIT",
          "RUBY_GC_OLDMALLOC_LIMIT_MAX",
          "RUBY_GC_OLDMALLOC_LIMIT_GROWTH_FACTOR",
          # INIT_SLOTS changed for Ruby 3.3+:
          # * https://bugs.ruby-lang.org/issues/19785
          # * https://www.ruby-lang.org/en/news/2023/12/25/ruby-3-3-0-released/#:~:text=Removed%20environment%20variables
          "RUBY_GC_HEAP_0_INIT_SLOTS",
          "RUBY_GC_HEAP_1_INIT_SLOTS",
          "RUBY_GC_HEAP_2_INIT_SLOTS",
          "RUBY_GC_HEAP_3_INIT_SLOTS",
          "RUBY_GC_HEAP_4_INIT_SLOTS",
          # There was only one setting for older Rubies:
          "RUBY_GC_HEAP_INIT_SLOTS",
          # Ruby 2.x only, alias for others:
          "RUBY_FREE_MIN",
          "RUBY_HEAP_MIN_SLOTS",
        ].freeze

        # Instead of trying to figure out real process start time by checking
        # /proc or some other complex/non-portable way, approximate start time
        # by time of requirement of this file.
        #
        # Note: this does not use Core::Utils::Time.now because this constant
        # gets initialized before a user has a chance to configure the library.
        START_TIME = Time.now.utc.freeze

        def collect_platform_info
          @platform_info ||= {
            container_id: Datadog::Core::Environment::Container.container_id,
            hostname: Datadog::Core::Environment::Platform.hostname,
            kernel_name: Datadog::Core::Environment::Platform.kernel_name,
            kernel_release: Datadog::Core::Environment::Platform.kernel_release,
            kernel_version: Datadog::Core::Environment::Platform.kernel_version
          }.freeze
        end

        def collect_runtime_info
          @runtime_info ||= {
            engine: Datadog::Core::Environment::Identity.lang_engine,
            version: Datadog::Core::Environment::Identity.lang_version,
            platform: Datadog::Core::Environment::Identity.lang_platform,
            gc_tuning: collect_gc_tuning_info,
          }.freeze
        end

        def collect_application_info(settings)
          @application_info ||= {
            start_time: START_TIME.iso8601,
            env: settings.env,
            service: settings.service,
            version: settings.version,
          }.freeze
        end

        def collect_profiler_info(settings)
          unless @profiler_info
            lib_datadog_gem = ::Gem.loaded_specs["libdatadog"]

            libdatadog_version =
              if lib_datadog_gem
                "#{lib_datadog_gem.version}-#{lib_datadog_gem.platform}"
              else
                # In some cases, Gem.loaded_specs may not be available, as in
                # https://github.com/DataDog/dd-trace-rb/pull/1506; let's use the version directly
                "#{Libdatadog::VERSION}-(unknown)"
              end

            @profiler_info = {
              version: Datadog::Core::Environment::Identity.gem_datadog_version,
              libdatadog: libdatadog_version,
              settings: collect_settings_recursively(settings.profiling),
            }.freeze
          end
          @profiler_info
        end

        # The settings/option model isn't directly serializable because
        # of subsettings and options that link to full blown custom object
        # instances without proper serialization.
        # This method navigates a settings object recursively, converting
        # it into more basic types that are trivially convertible to JSON.
        def collect_settings_recursively(v)
          v = v.options_hash if v.respond_to?(:options_hash)

          if v.nil? || v.is_a?(Symbol) || v.is_a?(Numeric) || v.is_a?(String) || v.equal?(true) || v.equal?(false)
            Core::Utils::SafeDup.frozen_or_dup(v)
          elsif v.is_a?(Hash)
            collected_hash = v.each_with_object({}) do |(key, value), hash|
              collected_value = collect_settings_recursively(value)
              hash[key] = collected_value
            end
            collected_hash.freeze
          elsif v.is_a?(Enumerable)
            collected_list = v
              .map { |value| collect_settings_recursively(value) }
            collected_list.freeze
          else
            v.inspect
          end
        end

        def collect_gc_tuning_info
          return @gc_tuning_info if defined?(@gc_tuning_info)

          @gc_tuning_info = RUBY_GC_TUNING_ENV_VARS.each_with_object({}) do |var, hash|
            current_value = ENV[var]
            hash[var.to_sym] = current_value if current_value
          end.freeze
        end
      end
    end
  end
end
