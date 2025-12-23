# frozen_string_literal: true

require "test_prof/ext/float_duration"
require "test_prof/ext/string_truncate"

module Minitest
  module TestProf
    class EventProfFormatter # :nodoc:
      using ::TestProf::FloatDuration
      using ::TestProf::StringTruncate

      def initialize(profilers)
        @profilers = profilers
        @results = []
      end

      def prepare_results
        @profilers.each do |profiler|
          total_results(profiler)
          by_groups(profiler)
          by_examples(profiler)
        end
        @results.join
      end

      private

      def total_results(profiler)
        time_percentage = time_percentage(profiler.total_time, profiler.absolute_run_time)

        @results <<
          <<~MSG
            EventProf results for #{profiler.event}

            Total time: #{profiler.total_time.duration} of #{profiler.absolute_run_time.duration} (#{time_percentage}%)
            Total events: #{profiler.total_count}

            Top #{profiler.top_count} slowest suites (by #{profiler.rank_by}):

          MSG
      end

      def by_groups(profiler)
        result = profiler.results
        groups = result[:groups]

        groups.each do |group|
          description = group[:id][:name]
          location = group[:id][:location]
          time = group[:time]
          run_time = group[:run_time]
          time_percentage = time_percentage(time, run_time)

          @results <<
            <<~GROUP
              #{description.truncate} (#{location}) – #{time.duration} (#{group[:count]} / #{group[:examples]}) of #{run_time.duration} (#{time_percentage}%)
            GROUP
        end
      end

      def by_examples(profiler)
        result = profiler.results
        examples = result[:examples]

        return unless examples
        @results << "\nTop #{profiler.top_count} slowest tests (by #{profiler.rank_by}):\n\n"

        examples.each do |example|
          description = example[:id][:name]
          location = example[:id][:location]
          time = example[:time]
          run_time = example[:run_time]
          time_percentage = time_percentage(time, run_time)

          @results <<
            <<~GROUP
              #{description.truncate} (#{location}) – #{time.duration} (#{example[:count]}) of #{run_time.duration} (#{time_percentage}%)
            GROUP
        end
      end

      def time_percentage(time, total_time)
        (time / total_time * 100).round(2)
      end
    end
  end
end
