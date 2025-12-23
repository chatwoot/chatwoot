# frozen_string_literal: true

require "test_prof/rspec_stamp"
require "test_prof/event_prof/profiler"
require "test_prof/event_prof/instrumentations/active_support"
require "test_prof/event_prof/monitor"
require "test_prof/utils/sized_ordered_set"

module TestProf
  # EventProf profiles your tests and suites against custom events,
  # such as ActiveSupport::Notifications.
  #
  # It works very similar to `rspec --profile` but can track arbitrary events.
  #
  # Example:
  #
  #   # Collect SQL queries stats for every suite and example
  #   EVENT_PROF='sql.active_record' rspec ...
  #
  # By default it collects information only about top-level groups (aka suites),
  # but you can also profile individual examples. Just set the configuration option:
  #
  #  TestProf::EventProf.configure do |config|
  #    config.per_example = true
  #  end
  #
  # Or provide the EVENT_PROF_EXAMPLES=1 env variable.
  module EventProf
    # EventProf configuration
    class Configuration
      # Map of supported instrumenters
      INSTRUMENTERS = {
        active_support: "ActiveSupport"
      }.freeze

      attr_accessor :instrumenter, :top_count, :per_example,
        :rank_by, :event

      def initialize
        @event = ENV["EVENT_PROF"]
        @instrumenter = :active_support
        @top_count = (ENV["EVENT_PROF_TOP"] || 5).to_i
        @per_example = ENV["EVENT_PROF_EXAMPLES"] == "1"
        @rank_by = (ENV["EVENT_PROF_RANK"] || :time).to_sym
        @stamp = ENV["EVENT_PROF_STAMP"]

        RSpecStamp.config.tags = @stamp if stamp?
      end

      def stamp?
        !@stamp.nil?
      end

      def per_example?
        per_example == true
      end

      def resolve_instrumenter
        return instrumenter if instrumenter.is_a?(Module)

        raise ArgumentError, "Unknown instrumenter: #{instrumenter}" unless
          INSTRUMENTERS.key?(instrumenter)

        Instrumentations.const_get(INSTRUMENTERS[instrumenter])
      end
    end

    class << self
      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      # Returns new configured instance of profilers group
      def build(event = config.event)
        ProfilersGroup.new(
          event: event,
          instrumenter: instrumenter,
          rank_by: config.rank_by,
          top_count: config.top_count,
          per_example: config.per_example?
        )
      end

      def instrumenter
        @instrumenter ||= config.resolve_instrumenter
      end

      # Instrument specified module methods.
      # Wraps them with `instrumenter.instrument(event) { ... }`.
      #
      # Use it to profile arbitrary methods:
      #
      #   TestProf::EventProf.monitor(MyModule, "my_module.call", :call)
      def monitor(mod, event, *mids, **kwargs)
        Monitor.call(mod, event, *mids, **kwargs)
      end
    end
  end
end

require "test_prof/event_prof/custom_events"
require "test_prof/event_prof/rspec" if TestProf.rspec?
require "test_prof/event_prof/minitest" if TestProf.minitest?
