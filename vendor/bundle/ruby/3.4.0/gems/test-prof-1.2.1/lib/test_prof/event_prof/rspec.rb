# frozen_string_literal: true

require "test_prof/ext/float_duration"
require "test_prof/ext/string_truncate"

module TestProf
  module EventProf
    class RSpecListener # :nodoc:
      include Logging
      using FloatDuration
      using StringTruncate

      NOTIFICATIONS = %i[
        example_group_started
        example_group_finished
        example_started
        example_finished
      ].freeze

      def initialize
        @profiler = EventProf.build

        log :info, "EventProf enabled (#{@profiler.events.join(", ")})"
      end

      def example_group_started(notification)
        return unless notification.group.top_level?
        @profiler.group_started notification.group
      end

      def example_group_finished(notification)
        return unless notification.group.top_level?
        @profiler.group_finished notification.group
      end

      def example_started(notification)
        @profiler.example_started notification.example
      end

      def example_finished(notification)
        @profiler.example_finished notification.example
      end

      def print
        @profiler.each(&method(:report))
      end

      def report(profiler)
        result = profiler.results
        time_percentage = time_percentage(profiler.total_time, profiler.absolute_run_time)

        msgs = []

        msgs <<
          <<~MSG
            EventProf results for #{profiler.event}

            Total time: #{profiler.total_time.duration} of #{profiler.absolute_run_time.duration} (#{time_percentage}%)
            Total events: #{profiler.total_count}

            Top #{profiler.top_count} slowest suites (by #{profiler.rank_by}):

          MSG

        result[:groups].each do |group|
          description = group[:id].top_level_description
          location = group[:id].metadata[:location]
          time = group[:time]
          run_time = group[:run_time]
          time_percentage = time_percentage(time, run_time)

          msgs <<
            <<~GROUP
              #{description.truncate} (#{location}) – #{time.duration} (#{group[:count]} / #{group[:examples]}) of #{run_time.duration} (#{time_percentage}%)
            GROUP
        end

        if result[:examples]
          msgs << "\nTop #{profiler.top_count} slowest tests (by #{profiler.rank_by}):\n\n"

          result[:examples].each do |example|
            description = example[:id].description
            location = example[:id].metadata[:location]
            time = example[:time]
            run_time = example[:run_time]
            time_percentage = time_percentage(time, run_time)

            msgs <<
              <<~GROUP
                #{description.truncate} (#{location}) – #{time.duration} (#{example[:count]}) of #{run_time.duration} (#{time_percentage}%)
              GROUP
          end
        end

        log :info, msgs.join

        stamp!(profiler) if EventProf.config.stamp?
      end

      def stamp!(profiler)
        result = profiler.results

        stamper = RSpecStamp::Stamper.new

        examples = Hash.new { |h, k| h[k] = [] }

        (result[:groups].to_a + result.fetch(:examples, []).to_a)
          .map { |obj| obj[:id].metadata[:location] }.each do |location|
          file, line = location.split(":")
          examples[file] << line.to_i
        end

        examples.each do |file, lines|
          stamper.stamp_file(file, lines.uniq)
        end

        msgs = []

        msgs <<
          <<~MSG
            RSpec Stamp results

            Total patches: #{stamper.total}
            Total files: #{examples.keys.size}

            Failed patches: #{stamper.failed}
            Ignored files: #{stamper.ignored}
          MSG

        log :info, msgs.join
      end

      def time_percentage(time, total_time)
        (time / total_time * 100).round(2)
      end
    end
  end
end

# Register EventProf listener
TestProf.activate("EVENT_PROF") do
  TestProf::EventProf::CustomEvents.activate_all(ENV["EVENT_PROF"])

  RSpec.configure do |config|
    listener = nil

    config.before(:suite) do
      listener = TestProf::EventProf::RSpecListener.new
      config.reporter.register_listener(
        listener, *TestProf::EventProf::RSpecListener::NOTIFICATIONS
      )
    end

    config.after(:suite) { listener&.print }
  end
end
