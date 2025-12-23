# frozen_string_literal: true

require 'erb'

module Rack
  class MiniProfiler

    # Timing system for a SQL query
    module TimerStruct
      class Sql < TimerStruct::Base
        attr_accessor :parent

        def initialize(query, duration_ms, page, parent, params = nil, skip_backtrace = false, full_backtrace = false)

          stack_trace = nil
          unless skip_backtrace || duration_ms < Rack::MiniProfiler.config.backtrace_threshold_ms
            # Allow us to filter the stack trace
            stack_trace = "".dup
            # Clean up the stack trace if there are options to do so
            Kernel.caller.each do |ln|
              ln.gsub!(Rack::MiniProfiler.config.backtrace_remove, '') if Rack::MiniProfiler.config.backtrace_remove && !full_backtrace
              if    full_backtrace ||
                    (
                      (
                        Rack::MiniProfiler.config.backtrace_includes.nil? ||
                        Rack::MiniProfiler.config.backtrace_includes.any? { |regex| ln =~ regex }
                      ) &&
                      (
                        Rack::MiniProfiler.config.backtrace_ignores.nil? ||
                        Rack::MiniProfiler.config.backtrace_ignores.none? { |regex| ln =~ regex }
                      )
                    )
                stack_trace << ln << "\n"
              end
            end
          end

          @parent      = parent
          @page        = page
          start_millis = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) * 1000).to_i - page[:started]) - duration_ms
          super(
            execute_type: 3, # TODO
            formatted_command_string: query ? ERB::Util.html_escape(query) : nil,
            stack_trace_snippet: stack_trace,
            start_milliseconds: start_millis,
            duration_milliseconds: duration_ms,
            first_fetch_duration_milliseconds: duration_ms,
            parameters: query ? trim_binds(params) : nil,
            parent_timing_id: nil,
            is_duplicate: false
          )
        end

        def report_reader_duration(elapsed_ms, row_count = nil, class_name = nil)
          return if @reported
          @reported = true
          self[:duration_milliseconds]                += elapsed_ms
          @parent[:sql_timings_duration_milliseconds] += elapsed_ms
          @page[:duration_milliseconds_in_sql]        += elapsed_ms
          self[:row_count] = self[:row_count].to_i + row_count if row_count
          self[:class_name] = class_name if class_name
        end

        def trim_binds(binds)
          max_len = Rack::MiniProfiler.config.max_sql_param_length
          return if binds.nil? || max_len == 0
          return binds.map { |(name, val)| [name, val] } if max_len.nil?
          binds.map do |(name, val)|
            val ||= name
            if val.nil? || val == true || val == false || val.kind_of?(Numeric)
              # keep these parameters as is
            elsif val.kind_of?(String)
              val = val[0...max_len] + (max_len < val.length ? '...' : '') if max_len
            else
              val = val.class.name
            end
            if name.kind_of?(String)
              name = name[0...max_len] + (max_len < name.length ? '...' : '') if max_len
            end
            [name, val]
          end
        end
      end
    end
  end
end
