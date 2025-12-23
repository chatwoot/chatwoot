# frozen_string_literal: true

require "minitest/base_reporter"
require "test_prof/ext/float_duration"

module Minitest
  module TestProf # :nodoc:
    # Add fd_ignore methods
    module FactoryDoctorIgnore
      def fd_ignore
        ::TestProf::FactoryDoctor.ignore!
      end
    end

    Minitest::Test.include FactoryDoctorIgnore

    class FactoryDoctorReporter < BaseReporter # :nodoc:
      using ::TestProf::FloatDuration

      SUCCESS_MESSAGE = 'FactoryDoctor says: "Looks good to me!"'

      def initialize(io = $stdout, options = {})
        super
        ::TestProf::FactoryDoctor.init
        @count = 0
        @time = 0.0
        @example_groups = Hash.new { |h, k| h[k] = [] }
      end

      def prerecord(_group, _example)
        ::TestProf::FactoryDoctor.start
      end

      def record(example)
        ::TestProf::FactoryDoctor.stop
        return if example.skipped? || ::TestProf::FactoryDoctor.ignore?

        result = ::TestProf::FactoryDoctor.result
        return unless result.bad?

        # Minitest::Result (>= 5.11) has `klass` method
        group_name = example.respond_to?(:klass) ? example.klass : example.class.name

        group = {
          description: group_name,
          location: location_without_line_number(example)
        }

        @example_groups[group] << {
          description: example.name.gsub(/^test_(?:\d+_)?/, ""),
          location: location_with_line_number(example),
          factories: result.count,
          time: result.time
        }

        @count += 1
        @time += result.time
      end

      def report
        return log(:info, SUCCESS_MESSAGE) if @example_groups.empty?

        msgs = []

        msgs <<
          <<~MSG
            FactoryDoctor report

            Total (potentially) bad examples: #{@count}
            Total wasted time: #{@time.duration}

          MSG

        @example_groups.each do |group, examples|
          msgs << "#{group[:description]} (#{group[:location]})\n"
          examples.each do |ex|
            msgs << "  #{ex[:description]} (#{ex[:location]}) " \
                    "– #{pluralize_records(ex[:factories])} created, " \
                    "#{ex[:time].duration}\n"
          end
          msgs << "\n"
        end

        log :info, msgs.join
      end

      private

      def pluralize_records(count)
        (count == 1) ? "1 record" : "#{count} records"
      end
    end
  end
end
