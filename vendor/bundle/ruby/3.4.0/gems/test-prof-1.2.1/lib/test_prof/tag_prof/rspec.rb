# frozen_string_literal: true

module TestProf
  module TagProf
    class RSpecListener # :nodoc:
      include Logging

      NOTIFICATIONS = %i[
        example_started
        example_finished
      ].freeze

      attr_reader :result, :printer

      def initialize
        @printer = (ENV["TAG_PROF_FORMAT"] == "html") ? Printers::HTML : Printers::Simple

        @result =
          if ENV["TAG_PROF_EVENT"].nil?
            Result.new ENV["TAG_PROF"].to_sym
          else
            require "test_prof/event_prof"

            @events_profiler = EventProf.build(ENV["TAG_PROF_EVENT"])

            Result.new ENV["TAG_PROF"].to_sym, @events_profiler.events
          end

        log :info, "TagProf enabled (#{result.tag})"
      end

      def example_started(_notification)
        @ts = TestProf.now
        # enable event profiling
        @events_profiler&.group_started(true)
      end

      def example_finished(notification)
        tag = notification.example.metadata.fetch(result.tag, :__unknown__)

        result.track(tag, time: TestProf.now - @ts, events: fetch_events_data)

        # reset and disable event profilers
        @events_profiler&.group_started(nil)
      end

      def report
        printer.dump(result)
      end

      private

      def fetch_events_data
        return {} unless @events_profiler

        @events_profiler.profilers.map do |profiler|
          [profiler.event, profiler.time]
        end.to_h
      end
    end
  end
end

# Register TagProf listener
TestProf.activate("TAG_PROF") do
  RSpec.configure do |config|
    listener = nil

    config.before(:suite) do
      listener = TestProf::TagProf::RSpecListener.new
      config.reporter.register_listener(
        listener, *TestProf::TagProf::RSpecListener::NOTIFICATIONS
      )
    end

    config.after(:suite) { listener&.report }
  end
end

# Activate custom events
TestProf.activate("TAG_PROF_EVENT") do
  require "test_prof/event_prof"

  TestProf::EventProf::CustomEvents.activate_all(ENV["TAG_PROF_EVENT"])
end
