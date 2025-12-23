# frozen_string_literal: true

require "test_prof/ext/float_duration"

module TestProf::FactoryProf
  module Printers
    # See https://twitter.com/nateberkopec/status/1389945187766456333
    module NateHeckler # :nodoc: all
      class << self
        using TestProf::FloatDuration
        include TestProf::Logging

        def dump(result, start_time:)
          return if result.raw_stats == {}

          total_time = result.stats.sum { |stat| stat[:top_level_time] }
          total_run_time = TestProf.now - start_time

          percentage = ((total_time / total_run_time) * 100).round(2)

          log :info, "Time spent in factories: #{total_time.duration} (#{percentage}% of total time)"
        end
      end
    end
  end
end
