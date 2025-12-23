# frozen_string_literal: true

require "test_prof/ext/float_duration"

module TestProf::FactoryProf
  module Printers
    module Simple # :nodoc: all
      class << self
        using TestProf::FloatDuration
        include TestProf::Logging

        def dump(result, start_time:)
          return log(:info, "No factories detected") if result.raw_stats == {}
          msgs = []

          total_run_time = TestProf.now - start_time
          total_count = result.stats.sum { |stat| stat[:total_count] }
          total_top_level_count = result.stats.sum { |stat| stat[:top_level_count] }
          total_time = result.stats.sum { |stat| stat[:top_level_time] }
          total_uniq_factories = result.stats.map { |stat| stat[:name] }.uniq.count

          msgs <<
            <<~MSG
              Factories usage

               Total: #{total_count}
               Total top-level: #{total_top_level_count}
               Total time: #{total_time.duration} (out of #{total_run_time.duration})
               Total uniq factories: #{total_uniq_factories}

                 total   top-level     total time      time per call      top-level time               name
            MSG

          result.stats.each do |stat|
            time_per_call = stat[:total_time] / stat[:total_count]

            msgs << format("%8d %11d %13.4fs %17.4fs %18.4fs %18s", stat[:total_count], stat[:top_level_count], stat[:total_time], time_per_call, stat[:top_level_time], stat[:name])
          end

          log :info, msgs.join("\n")
        end
      end
    end
  end
end
