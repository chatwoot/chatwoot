# frozen_string_literal: true

module Datadog
  module Profiling
    # Responsible for wiring up the Profiler for execution
    module Component
      ALLOCATION_WITH_RACTORS_ONLY_ONCE = Datadog::Core::Utils::OnlyOnce.new
      private_constant :ALLOCATION_WITH_RACTORS_ONLY_ONCE

      # Passing in a `nil` tracer is supported and will disable the following profiling features:
      # * Profiling in the trace viewer, as well as scoping a profile down to a span
      # * Endpoint aggregation in the profiler UX, including normalization (resource per endpoint call)
      def self.build_profiler_component(settings:, agent_settings:, optional_tracer:, logger:) # rubocop:disable Metrics/MethodLength
        return [nil, {profiling_enabled: false}] unless settings.profiling.enabled

        # Workaround for weird dependency direction: the Core::Configuration::Components class currently has a
        # dependency on individual products, in this case the Profiler.
        # (Note "currently": in the future we want to change this so core classes don't depend on specific products)
        #
        # If the current file included a `require 'datadog/profiler'` at its beginning, we would generate circular
        # requires when used from profiling:
        #
        # datadog/profiling
        #     └─requires─> datadog/core
        #                      └─requires─> datadog/core/configuration/components
        #                                       └─requires─> datadog/profiling       # Loop!
        #
        # ...thus in #1998 we removed such a require.
        #
        # On the other hand, if datadog/core is loaded by a different product and no general `require 'datadog'` is
        # done, then profiling may not be loaded, and thus to avoid this issue we do a require here (which is a
        # no-op if profiling is already loaded).
        require_relative "../profiling"

        return [nil, {profiling_enabled: false}] unless Profiling.supported?

        # Activate forking extensions
        Profiling::Tasks::Setup.new.run

        # NOTE: Please update the Initialization section of ProfilingDevelopment.md with any changes to this method

        no_signals_workaround_enabled = no_signals_workaround_enabled?(settings, logger)
        timeline_enabled = settings.profiling.advanced.timeline_enabled
        allocation_profiling_enabled = enable_allocation_profiling?(settings, logger)
        heap_sample_every = get_heap_sample_every(settings)
        heap_profiling_enabled = enable_heap_profiling?(settings, allocation_profiling_enabled, heap_sample_every, logger)
        heap_size_profiling_enabled = enable_heap_size_profiling?(settings, heap_profiling_enabled, logger)

        overhead_target_percentage = valid_overhead_target(settings.profiling.advanced.overhead_target_percentage, logger)
        upload_period_seconds = [60, settings.profiling.advanced.upload_period_seconds].max

        recorder = Datadog::Profiling::StackRecorder.new(
          cpu_time_enabled: RUBY_PLATFORM.include?("linux"), # Only supported on Linux currently
          alloc_samples_enabled: allocation_profiling_enabled,
          heap_samples_enabled: heap_profiling_enabled,
          heap_size_enabled: heap_size_profiling_enabled,
          heap_sample_every: heap_sample_every,
          timeline_enabled: timeline_enabled,
          heap_clean_after_gc_enabled: settings.profiling.advanced.heap_clean_after_gc_enabled,
        )
        thread_context_collector = build_thread_context_collector(settings, recorder, optional_tracer, timeline_enabled)
        worker = Datadog::Profiling::Collectors::CpuAndWallTimeWorker.new(
          gc_profiling_enabled: enable_gc_profiling?(settings, logger),
          no_signals_workaround_enabled: no_signals_workaround_enabled,
          thread_context_collector: thread_context_collector,
          dynamic_sampling_rate_overhead_target_percentage: overhead_target_percentage,
          allocation_profiling_enabled: allocation_profiling_enabled,
          allocation_counting_enabled: settings.profiling.advanced.allocation_counting_enabled,
          gvl_profiling_enabled: enable_gvl_profiling?(settings, logger),
          sighandler_sampling_enabled: settings.profiling.advanced.sighandler_sampling_enabled,
        )

        internal_metadata = {
          no_signals_workaround_enabled: no_signals_workaround_enabled,
          timeline_enabled: timeline_enabled,
          heap_sample_every: heap_sample_every,
        }.freeze

        exporter = build_profiler_exporter(settings, recorder, worker, internal_metadata: internal_metadata)
        transport = build_profiler_transport(settings, agent_settings)
        scheduler = Profiling::Scheduler.new(exporter: exporter, transport: transport, interval: upload_period_seconds)
        profiler = Profiling::Profiler.new(worker: worker, scheduler: scheduler)

        if dir_interruption_workaround_enabled?(settings, no_signals_workaround_enabled)
          Datadog::Profiling::Ext::DirMonkeyPatches.apply!
        end

        [profiler, {profiling_enabled: true}]
      end

      private_class_method def self.build_thread_context_collector(settings, recorder, optional_tracer, timeline_enabled)
        Datadog::Profiling::Collectors::ThreadContext.new(
          recorder: recorder,
          max_frames: settings.profiling.advanced.max_frames,
          tracer: optional_tracer,
          endpoint_collection_enabled: settings.profiling.advanced.endpoint.collection.enabled,
          timeline_enabled: timeline_enabled,
          waiting_for_gvl_threshold_ns: settings.profiling.advanced.waiting_for_gvl_threshold_ns,
          otel_context_enabled: settings.profiling.advanced.preview_otel_context_enabled,
          native_filenames_enabled: settings.profiling.advanced.native_filenames_enabled,
        )
      end

      private_class_method def self.build_profiler_exporter(settings, recorder, worker, internal_metadata:)
        info_collector = Profiling::Collectors::Info.new(settings)
        code_provenance_collector =
          (Profiling::Collectors::CodeProvenance.new if settings.profiling.advanced.code_provenance_enabled)

        Profiling::Exporter.new(
          pprof_recorder: recorder,
          worker: worker,
          info_collector: info_collector,
          code_provenance_collector: code_provenance_collector,
          internal_metadata: internal_metadata,
        )
      end

      private_class_method def self.build_profiler_transport(settings, agent_settings)
        settings.profiling.exporter.transport ||
          Profiling::HttpTransport.new(
            agent_settings: agent_settings,
            site: settings.site,
            api_key: settings.api_key,
            upload_timeout_seconds: settings.profiling.upload.timeout_seconds,
          )
      end

      private_class_method def self.enable_gc_profiling?(settings, logger)
        return false unless settings.profiling.advanced.gc_enabled

        # SEVERE - Only with Ractors
        # On Ruby versions 3.0 (all), 3.1.0 to 3.1.3, and 3.2.0 to 3.2.2 gc profiling can trigger a VM bug
        # that causes a segmentation fault during garbage collection of Ractors
        # (https://bugs.ruby-lang.org/issues/18464). We don't allow enabling gc profiling on such Rubies.
        # This bug is fixed on Ruby versions 3.1.4, 3.2.3 and 3.3.0.
        if RUBY_VERSION.start_with?("3.0.") ||
            (RUBY_VERSION.start_with?("3.1.") && RUBY_VERSION < "3.1.4") ||
            (RUBY_VERSION.start_with?("3.2.") && RUBY_VERSION < "3.2.3")
          logger.warn(
            "Current Ruby version (#{RUBY_VERSION}) has a VM bug where enabling GC profiling would cause " \
            "crashes (https://bugs.ruby-lang.org/issues/18464). GC profiling has been disabled."
          )
          return false
        elsif RUBY_VERSION.start_with?("3.")
          logger.debug(
            "Using Ractors may result in GC profiling unexpectedly " \
            "stopping (https://bugs.ruby-lang.org/issues/19112). Note that this stop has no impact in your " \
            "application stability or performance. This does not happen if Ractors are not used."
          )
        end

        true
      end

      private_class_method def self.get_heap_sample_every(settings)
        heap_sample_rate = settings.profiling.advanced.experimental_heap_sample_rate

        raise ArgumentError, "Heap sample rate must be a positive integer. Was #{heap_sample_rate}" if heap_sample_rate <= 0

        heap_sample_rate
      end

      private_class_method def self.enable_allocation_profiling?(settings, logger)
        return false unless settings.profiling.allocation_enabled

        # Allocation sampling is safe and supported on Ruby 2.x, but has a few caveats on Ruby 3.x.

        # SEVERE - All configurations
        # Ruby 3.2.0 to 3.2.2 have a bug in the newobj tracepoint (https://bugs.ruby-lang.org/issues/19482,
        # https://github.com/ruby/ruby/pull/7464) that makes this crash in any configuration. This bug is
        # fixed on Ruby versions 3.2.3 and 3.3.0.
        if RUBY_VERSION.start_with?("3.2.") && RUBY_VERSION < "3.2.3"
          logger.warn(
            "Allocation profiling is not supported in Ruby versions 3.2.0, 3.2.1 and 3.2.2 and will be forcibly " \
            "disabled. This is due to a VM bug that can lead to crashes (https://bugs.ruby-lang.org/issues/19482). " \
            "Other Ruby versions do not suffer from this issue."
          )
          return false
        end

        # SEVERE - Only with Ractors
        # On Ruby versions 3.0 (all), 3.1.0 to 3.1.3, and 3.2.0 to 3.2.2 allocation profiling can trigger a VM bug
        # that causes a segmentation fault during garbage collection of Ractors
        # (https://bugs.ruby-lang.org/issues/18464). We don't recommend using this feature on such Rubies.
        # This bug is fixed on Ruby versions 3.1.4, 3.2.3 and 3.3.0.
        if RUBY_VERSION.start_with?("3.0.") ||
            (RUBY_VERSION.start_with?("3.1.") && RUBY_VERSION < "3.1.4") ||
            (RUBY_VERSION.start_with?("3.2.") && RUBY_VERSION < "3.2.3")
          logger.warn(
            "Current Ruby version (#{RUBY_VERSION}) has a VM bug where enabling allocation profiling while using " \
            "Ractors may cause unexpected issues, including crashes (https://bugs.ruby-lang.org/issues/18464). " \
            "This does not happen if Ractors are not used."
          )
        # ANNOYANCE - Only with Ractors
        # On all known versions of Ruby 3.x, due to https://bugs.ruby-lang.org/issues/19112, when a ractor gets
        # garbage collected, Ruby will disable all active tracepoints, which this feature internally relies on.
        elsif RUBY_VERSION.start_with?("3.")
          ALLOCATION_WITH_RACTORS_ONLY_ONCE.run do
            logger.info(
              "Using Ractors may result in allocation profiling " \
              "stopping (https://bugs.ruby-lang.org/issues/19112). Note that this stop has no impact in your " \
              "application stability or performance. This does not happen if Ractors are not used."
            )
          end
        end

        logger.debug("Enabled allocation profiling")

        true
      end

      private_class_method def self.enable_heap_profiling?(settings, allocation_profiling_enabled, heap_sample_rate, logger)
        heap_profiling_enabled = settings.profiling.advanced.experimental_heap_enabled

        return false unless heap_profiling_enabled

        if RUBY_VERSION < "3.1"
          logger.warn(
            "Current Ruby version (#{RUBY_VERSION}) cannot support heap profiling due to VM limitations. " \
            "Please upgrade to Ruby >= 3.1 in order to use this feature. Heap profiling has been disabled."
          )
          return false
        end

        unless allocation_profiling_enabled
          logger.warn(
            "Heap profiling was requested but allocation profiling is not enabled. " \
            "Heap profiling has been disabled."
          )
          return false
        end

        logger.debug("Enabled heap profiling: heap_sample_rate=#{heap_sample_rate}")

        true
      end

      private_class_method def self.enable_heap_size_profiling?(settings, heap_profiling_enabled, logger)
        heap_size_profiling_enabled = settings.profiling.advanced.experimental_heap_size_enabled

        return false unless heap_profiling_enabled && heap_size_profiling_enabled

        true
      end

      private_class_method def self.no_signals_workaround_enabled?(settings, logger) # rubocop:disable Metrics/MethodLength
        setting_value = settings.profiling.advanced.no_signals_workaround_enabled

        unless [true, false, :auto].include?(setting_value)
          logger.warn(
            "Ignoring invalid value for profiling no_signals_workaround_enabled setting: #{setting_value.inspect}. " \
            "Valid options are `true`, `false` or (default) `:auto`."
          )

          setting_value = :auto
        end

        if setting_value == false
          if RUBY_VERSION.start_with?("2.5.")
            logger.warn(
              'The profiling "no signals" workaround has been disabled via configuration on Ruby 2.5. ' \
              "This is not recommended " \
              "in production environments, as due to limitations in Ruby APIs, we suspect it may lead to rare crashes " \
              "Please report any issues you run into to Datadog support or " \
              "via <https://github.com/datadog/dd-trace-rb/issues/new>!"
            )
          else
            logger.warn('Profiling "no signals" workaround disabled via configuration')
          end

          return false
        end

        if setting_value == true
          logger.warn(
            'Profiling "no signals" workaround enabled via configuration. Profiling data will have lower quality.'
          )

          return true
        end

        # Setting is in auto mode. Let's probe to see if we should enable it:

        # We don't warn users in this situation because "upgrade your Ruby" is not a great warning
        return true if RUBY_VERSION.start_with?("2.5.")

        if Gem.loaded_specs["mysql2"] && incompatible_libmysqlclient_version?(settings, logger)
          logger.warn(
            'Enabling the profiling "no signals" workaround because an incompatible version of the mysql2 gem is ' \
            "installed. Profiling data will have lower quality. " \
            "To fix this, upgrade the libmysqlclient in your OS image to version 8.0.0 or above."
          )
          return true
        end

        if Gem.loaded_specs["rugged"]
          logger.warn(
            'Enabling the profiling "no signals" workaround because the rugged gem is installed. ' \
            "This is needed because some operations on this gem are currently incompatible with the normal working mode " \
            "of the profiler, as detailed in <https://github.com/datadog/dd-trace-rb/issues/2721>. " \
            "Profiling data will have lower quality."
          )
          return true
        end

        if (defined?(::PhusionPassenger) || Gem.loaded_specs["passenger"]) && incompatible_passenger_version?
          logger.warn(
            'Enabling the profiling "no signals" workaround because an incompatible version of the passenger gem is ' \
            "installed. Profiling data will have lower quality." \
            "To fix this, upgrade the passenger gem to version 6.0.19 or above."
          )
          return true
        end

        false
      end

      # Versions of libmysqlclient prior to 8.0.0 are known to have buggy handling of system call interruptions.
      # The profiler can sometimes cause system call interruptions, and so this combination can cause queries to fail.
      #
      # See https://bugs.mysql.com/bug.php?id=83109 and
      # https://docs.datadoghq.com/profiler/profiler_troubleshooting/ruby/#unexpected-run-time-failures-and-errors-from-ruby-gems-that-use-native-extensions-in-dd-trace-rb-1110
      # for details.
      #
      # The `mysql2` gem's `info` method can be used to determine which `libmysqlclient` version is in use, and thus to
      # detect if it's safe for the profiler to use signals or if we need to employ a fallback.
      private_class_method def self.incompatible_libmysqlclient_version?(settings, logger)
        return true if settings.profiling.advanced.skip_mysql2_check

        logger.debug(
          "Requiring `mysql2` to check if the `libmysqlclient` version it uses is compatible with profiling"
        )

        begin
          require "mysql2"

          # The mysql2-aurora gem likes to monkey patch itself in replacement of Mysql2::Client, and uses
          # `method_missing` to delegate to the original BUT unfortunately does not implement `respond_to_missing?` and
          # thus our `respond_to?(:info)` below was failing.
          #
          # But on the bright side, the gem does stash a reference to the original Mysql2::Client class in a constant,
          # so if that constant exists, we use that for our probing.
          mysql2_client_class =
            if defined?(Mysql2::Aurora::ORIGINAL_CLIENT_CLASS)
              Mysql2::Aurora::ORIGINAL_CLIENT_CLASS
            elsif defined?(Mysql2::Client)
              Mysql2::Client
            end

          return true unless mysql2_client_class && mysql2_client_class.respond_to?(:info)

          info = mysql2_client_class.info
          libmysqlclient_version = Gem::Version.new(info[:version])

          compatible =
            libmysqlclient_version >= Gem::Version.new("8.0.0") ||
            looks_like_mariadb?(info, libmysqlclient_version)

          logger.debug(
            "The `mysql2` gem is using #{compatible ? "a compatible" : "an incompatible"} version of " \
            "the `libmysqlclient` library (#{libmysqlclient_version})"
          )

          !compatible
        rescue StandardError, LoadError => e
          logger.warn(
            "Failed to probe `mysql2` gem information. " \
            "Cause: #{e.class.name} #{e.message} Location: #{Array(e.backtrace).first}"
          )

          true
        end
      end

      # See https://github.com/datadog/dd-trace-rb/issues/2976 for details.
      private_class_method def self.incompatible_passenger_version?
        first_compatible_version = Gem::Version.new("6.0.19")

        if Gem.loaded_specs["passenger"]
          Gem.loaded_specs["passenger"].version < first_compatible_version
        elsif defined?(PhusionPassenger::VERSION_STRING)
          Gem::Version.new(PhusionPassenger::VERSION_STRING) < first_compatible_version
        else
          true
        end
      end

      private_class_method def self.valid_overhead_target(overhead_target_percentage, logger)
        if overhead_target_percentage > 0 && overhead_target_percentage <= 20
          overhead_target_percentage
        else
          logger.warn(
            "Ignoring invalid value for profiling overhead_target_percentage setting: " \
            "#{overhead_target_percentage.inspect}. Falling back to default value."
          )

          2.0
        end
      end

      # To add just a bit more complexity to our detection code, in https://github.com/DataDog/dd-trace-rb/issues/3334
      # a user reported that our code was incorrectly flagging the mariadb variant of libmysqlclient as being
      # incompatible. In fact we have no reports of the mariadb variant needing the "no signals" workaround,
      # so we flag it as compatible when it's in use.
      #
      # A problem is that there doesn't seem to be an obvious way to query the mysql2 gem on which kind of
      # libmysqlclient it's using, so we detect it by looking at the version.
      #
      # The info method for mysql2 with mariadb looks something like this:
      # `{:id=>30308, :version=>"3.3.8", :header_version=>"11.2.2"}`
      #
      # * The version seems to come from https://github.com/mariadb-corporation/mariadb-connector-c and the latest
      # one is 3.x.
      # * The header_version is what people usually see as the "mariadb version"
      #
      # As a comparison, for libmysql the info looks like:
      # * `{:id=>80035, :version=>"8.0.35", :header_version=>"8.0.35"}`
      #
      # Thus our detection is version 4 or older, because libmysqlclient 4 is almost 20 years old so it's most probably
      # not that one + header_version being 10 or newer, since according to https://endoflife.date/mariadb that's a
      # sane range for modern mariadb releases.
      private_class_method def self.looks_like_mariadb?(info, libmysqlclient_version)
        header_version = Gem::Version.new(info[:header_version]) if info[:header_version]

        !!(header_version &&
          libmysqlclient_version < Gem::Version.new("5.0.0") &&
          header_version >= Gem::Version.new("10.0.0"))
      end

      private_class_method def self.dir_interruption_workaround_enabled?(settings, no_signals_workaround_enabled)
        return false if no_signals_workaround_enabled || RUBY_VERSION >= "3.4"

        settings.profiling.advanced.dir_interruption_workaround_enabled
      end

      private_class_method def self.enable_gvl_profiling?(settings, logger)
        return false if RUBY_VERSION < "3.2"

        # GVL profiling only makes sense in the context of timeline. We could emit a warning here, but not sure how
        # useful it is -- if a customer disables timeline, there's nowhere to look for GVL profiling anyway!
        settings.profiling.advanced.timeline_enabled && settings.profiling.advanced.gvl_enabled
      end
    end
  end
end
