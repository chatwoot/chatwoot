# frozen_string_literal: true

module Rack
  class MiniProfiler
    module TimerStruct
      class Request < TimerStruct::Base

        def self.createRoot(name, page)
          TimerStruct::Request.new(name, page, nil).tap do |timer|
            timer[:is_root] = true
          end
        end

        attr_accessor :children_duration, :start, :parent

        def initialize(name, page, parent)
          start_millis = (Process.clock_gettime(Process::CLOCK_MONOTONIC) * 1000).to_i - page[:started]
          depth        = parent ? parent.depth + 1 : 0
          super(
            id: MiniProfiler.generate_id,
            name: name,
            duration_milliseconds: 0,
            duration_without_children_milliseconds: 0,
            start_milliseconds: start_millis,
            parent_timing_id: nil,
            children: [],
            has_children: false,
            key_values: nil,
            has_sql_timings: false,
            has_duplicate_sql_timings: false,
            trivial_duration_threshold_milliseconds: 2,
            sql_timings: [],
            sql_timings_duration_milliseconds: 0,
            is_trivial: false,
            is_root: false,
            depth: depth,
            executed_readers: 0,
            executed_scalars: 0,
            executed_non_queries: 0,
            custom_timing_stats: {},
            custom_timings: {}
          )
          @children_duration = 0
          @start             = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          @parent            = parent
          @page              = page
        end

        def name
          @attributes[:name]
        end

        def duration_ms
          self[:duration_milliseconds]
        end

        def duration_ms_in_sql
          @attributes[:duration_milliseconds_in_sql]
        end

        def start_ms
          self[:start_milliseconds]
        end

        def depth
          self[:depth]
        end

        def children
          self[:children]
        end

        def custom_timings
          self[:custom_timings]
        end

        def sql_timings
          self[:sql_timings]
        end

        def add_child(name)
          TimerStruct::Request.new(name, @page, self).tap do |timer|
            self[:children].push(timer)
            self[:has_children]      = true
            timer[:parent_timing_id] = self[:id]
            timer[:depth]            = self[:depth] + 1
          end
        end

        def move_child(child, destination)
          if index = self[:children].index(child)
            self[:children].slice!(index)
            self[:has_children] = self[:children].size > 0

            destination[:children].push(child)
            destination[:has_children] = true

            child[:parent_timing_id] = destination[:id]
            child.parent = destination
            child.adjust_depth
          end
        end

        def add_sql(query, elapsed_ms, page, params = nil, skip_backtrace = false, full_backtrace = false)
          TimerStruct::Sql.new(query, elapsed_ms, page, self, params, skip_backtrace, full_backtrace).tap do |timer|
            self[:sql_timings].push(timer)
            timer[:parent_timing_id] = self[:id]
            self[:has_sql_timings]   = true
            self[:sql_timings_duration_milliseconds] += elapsed_ms
            page[:duration_milliseconds_in_sql]      += elapsed_ms
            page[:sql_count] += 1
          end
        end

        def move_sql(sql, destination)
          if index = self[:sql_timings].index(sql)
            self[:sql_timings].slice!(index)
            self[:has_sql_timings] = self[:sql_timings].size > 0
            self[:sql_timings_duration_milliseconds] -= sql[:duration_milliseconds]
            destination[:sql_timings].push(sql)
            destination[:has_sql_timings] = true
            destination[:sql_timings_duration_milliseconds] += sql[:duration_milliseconds]
            sql[:parent_timing_id] = destination[:id]
            sql.parent = destination
          end
        end

        # please call SqlTiming#report_reader_duration instead
        def report_reader_duration(elapsed_ms, row_count = nil, class_name = nil)
          last_time = self[:sql_timings]&.last
          last_time&.report_reader_duration(elapsed_ms, row_count, class_name)
        end

        def add_custom(type, elapsed_ms, page)
          TimerStruct::Custom.new(type, elapsed_ms, page, self).tap do |timer|
            timer[:parent_timing_id] = self[:id]

            self[:custom_timings][type] ||= []
            self[:custom_timings][type].push(timer)

            self[:custom_timing_stats][type] ||= { count: 0, duration: 0.0 }
            self[:custom_timing_stats][type][:count]    += 1
            self[:custom_timing_stats][type][:duration] += elapsed_ms

            page[:custom_timing_stats][type] ||= { count: 0, duration: 0.0 }
            page[:custom_timing_stats][type][:count]    += 1
            page[:custom_timing_stats][type][:duration] += elapsed_ms
          end
        end

        def move_custom(type, custom, destination)
          if index = self[:custom_timings][type]&.index(custom)
            custom[:parent_timing_id] = destination[:id]
            custom.parent = destination
            self[:custom_timings][type].slice!(index)
            if self[:custom_timings][type].size == 0
              self[:custom_timings].delete(type)
              self[:custom_timing_stats].delete(type)
            else
              self[:custom_timing_stats][type][:count] -= 1
              self[:custom_timing_stats][type][:duration] -= custom[:duration_milliseconds]
            end
            destination[:custom_timings][type] ||= []
            destination[:custom_timings][type].push(custom)
            destination[:custom_timing_stats][type] ||= { count: 0, duration: 0.0 }
            destination[:custom_timing_stats][type][:count] += 1
            destination[:custom_timing_stats][type][:duration] += custom[:duration_milliseconds]
          end
        end

        def record_time(milliseconds = nil)
          milliseconds ||= (Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start) * 1000
          self[:duration_milliseconds]                  = milliseconds
          self[:is_trivial]                             = true if milliseconds < self[:trivial_duration_threshold_milliseconds]
          self[:duration_without_children_milliseconds] = milliseconds - self[:children].sum(&:duration_ms)
        end

        def adjust_depth
          self[:depth] = self.parent ? self.parent[:depth] + 1 : 0
          self[:children].each(&:adjust_depth)
        end
      end
    end
  end
end
