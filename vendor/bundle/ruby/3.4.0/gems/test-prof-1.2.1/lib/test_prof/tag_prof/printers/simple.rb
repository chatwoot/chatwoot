# frozen_string_literal: true

require "test_prof/ext/float_duration"

module TestProf::TagProf
  module Printers
    module Simple # :nodoc: all
      class << self
        include TestProf::Logging
        using TestProf::FloatDuration

        def dump(result)
          msgs = []

          msgs <<
            <<~MSG
              TagProf report for #{result.tag}
            MSG

          header = []

          header << format(
            "%15s  %12s  ",
            result.tag, "time"
          )

          events_format = nil

          unless result.events.empty?
            events_format = result.events.map { |event| "%#{event.size + 2}s  " }.join

            header << format(
              events_format,
              *result.events
            )
          end

          header << format(
            "%6s  %6s  %6s  %12s",
            "total", "%total", "%time", "avg"
          )

          msgs << header.join

          msgs << ""

          total = result.data.values.inject(0) { |acc, v| acc + v[:count] }
          total_time = result.data.values.inject(0) { |acc, v| acc + v[:time] }

          result.data.values.sort_by { |v| -v[:time] }.each do |tag|
            line = []
            line << format(
              "%15s  %12s  ",
              tag[:value], tag[:time].duration
            )

            unless result.events.empty?
              line << format(
                events_format,
                *result.events.map { |event| tag[event].duration }
              )
            end

            line << format(
              "%6d  %6.2f  %6.2f  %12s",
              tag[:count],
              100 * tag[:count].to_f / total,
              100 * tag[:time] / total_time,
              (tag[:time] / tag[:count]).duration
            )

            msgs << line.join
          end

          log :info, msgs.join("\n")
        end
      end
    end
  end
end
