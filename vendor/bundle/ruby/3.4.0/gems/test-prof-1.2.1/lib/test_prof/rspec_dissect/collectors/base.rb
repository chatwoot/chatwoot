# frozen_string_literal: true

require "test_prof/utils/sized_ordered_set"
require "test_prof/ext/float_duration"
require "test_prof/ext/string_truncate"

module TestProf # :nodoc: all
  using FloatDuration
  using StringTruncate

  module RSpecDissect
    module Collectors
      class Base
        attr_reader :results, :name, :top_count

        def initialize(name:, top_count:)
          @name = name
          @top_count = top_count
          @results = Utils::SizedOrderedSet.new(
            top_count, sort_by: name
          )
        end

        def populate!(data)
          data[name] = RSpecDissect.time_for(name)
        end

        def <<(data)
          results << data
        end

        def total_time
          RSpecDissect.total_time_for(name)
        end

        def total_time_message
          "\nTotal `#{print_name}` time: #{total_time.duration}"
        end

        def print_name
          name
        end

        def print_result_header
          <<~MSG

            Top #{top_count} slowest suites (by `#{print_name}` time):

          MSG
        end

        def print_group_result(group)
          <<~GROUP
            #{group[:desc].truncate} (#{group[:loc]}) – #{group[name].duration} of #{group[:total].duration} (#{group[:count]})
          GROUP
        end

        def print_results
          msgs = [print_result_header]

          results.each do |group|
            msgs << print_group_result(group)
          end

          msgs.join
        end
      end
    end
  end
end
