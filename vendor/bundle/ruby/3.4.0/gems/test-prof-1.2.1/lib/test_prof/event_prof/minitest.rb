# frozen_string_literal: true

require "minitest/base_reporter"
require "minitest/event_prof_formatter"

module Minitest
  module TestProf
    class EventProfReporter < BaseReporter # :nodoc:
      def initialize(io = $stdout, options = {})
        super
        @profiler = configure_profiler(options)

        log :info, "EventProf enabled (#{@profiler.events.join(", ")})"

        @formatter = EventProfFormatter.new(@profiler)
        @current_group = nil
        @current_example = nil
      end

      def prerecord(group, example)
        change_current_group(group, example) unless @current_group
        track_current_example(group, example)
      end

      def before_test(test)
        prerecord(test.class, test.name)
      end

      def record(*)
        @profiler.example_finished(@current_example)
      end

      def report
        @profiler.group_finished(@current_group)
        result = @formatter.prepare_results
        log :info, result
      end

      private

      def track_current_example(group, example)
        unless @current_group[:name] == group.name
          @profiler.group_finished(@current_group)
          change_current_group(group, example)
        end

        @current_example = {
          name: example.gsub(/^test_(?:\d+_)?/, ""),
          location: location_with_line_number(group, example)
        }

        @profiler.example_started(@current_example)
      end

      def change_current_group(group, example)
        @current_group = {
          name: group.name,
          location: location_without_line_number(group, example)
        }

        @profiler.group_started(@current_group)
      end

      def configure_profiler(options)
        ::TestProf::EventProf.configure do |config|
          config.event = options[:event]
          config.rank_by = options[:rank_by] if options[:rank_by]
          config.top_count = options[:top_count] if options[:top_count]
          config.per_example = options[:per_example] if options[:per_example]

          ::TestProf::EventProf::CustomEvents.activate_all config.event
        end

        ::TestProf::EventProf.build
      end
    end
  end
end
