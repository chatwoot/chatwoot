# frozen_string_literal: true

module Rack
  class MiniProfiler
    module ProfilingMethods

      def record_sql(query, elapsed_ms, params = nil)
        return unless current && current.current_timer
        c = current
        c.current_timer.add_sql(
          redact_sql_queries? ? nil : query,
          elapsed_ms,
          c.page_struct,
          redact_sql_queries? ? nil : params,
          c.skip_backtrace,
          c.full_backtrace
        )
      end

      def report_reader_duration(elapsed_ms, row_count = nil, class_name = nil)
        current&.current_timer&.report_reader_duration(elapsed_ms, row_count, class_name)
      end

      def start_step(name)
        return unless current
        parent_timer          = current.current_timer
        current.current_timer = current_timer = current.current_timer.add_child(name)
        [current_timer, parent_timer]
      end

      def finish_step(obj)
        return unless obj && current
        current_timer, parent_timer = obj
        current_timer.record_time
        current.current_timer = parent_timer
      end

      # perform a profiling step on given block
      def step(name, opts = nil)
        if current
          parent_timer          = current.current_timer
          current.current_timer = current_timer = current.current_timer.add_child(name)
          begin
            yield if block_given?
          ensure
            current_timer.record_time
            current.current_timer = parent_timer
          end
        else
          yield if block_given?
        end
      end

      def unprofile_method(klass, method)

        clean = clean_method_name(method)

        with_profiling = ("#{clean}_with_mini_profiler").intern
        without_profiling = ("#{clean}_without_mini_profiler").intern

        if klass.send :method_defined?, with_profiling
          klass.send :alias_method, method, without_profiling
          klass.send :remove_method, with_profiling
          klass.send :remove_method, without_profiling
        end
      end

      def counter_method(klass, method, &blk)
        self.profile_method(klass, method, :counter, &blk)
      end

      def uncounter_method(klass, method)
        self.unprofile_method(klass, method)
      end

      def profile_method(klass, method, type = :profile, &blk)
        default_name = type == :counter ? method.to_s : klass.to_s + " " + method.to_s
        clean        = clean_method_name(method)

        with_profiling    = ("#{clean}_with_mini_profiler").intern
        without_profiling = ("#{clean}_without_mini_profiler").intern

        if klass.send :method_defined?, with_profiling
          return # dont double profile
        end

        klass.send :alias_method, without_profiling, method
        klass.send :define_method, with_profiling do |*args, &orig|
          return self.send without_profiling, *args, &orig unless Rack::MiniProfiler.current

          name = default_name
          if blk
            name =
              if respond_to?(:instance_exec)
                instance_exec(*args, &blk)
              else
                # deprecated in Rails 4.x
                blk.bind(self).call(*args)
              end
          end

          parent_timer = Rack::MiniProfiler.current.current_timer

          if type == :counter
            start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            begin
              self.send without_profiling, *args, &orig
            ensure
              duration_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).to_f * 1000
              parent_timer.add_custom(name, duration_ms, Rack::MiniProfiler.current.page_struct)
            end
          else
            Rack::MiniProfiler.current.current_timer = current_timer = parent_timer.add_child(name)
            begin
              self.send without_profiling, *args, &orig
            ensure
              current_timer.record_time
              Rack::MiniProfiler.current.current_timer = parent_timer
            end
          end
        end
        if klass.respond_to?(:ruby2_keywords, true)
          klass.send(:ruby2_keywords, with_profiling)
        end
        klass.send :alias_method, method, with_profiling
      end

      def profile_singleton_method(klass, method, type = :profile, &blk)
        profile_method(klass.singleton_class, method, type, &blk)
      end

      def unprofile_singleton_method(klass, method)
        unprofile_method(klass.singleton_class, method)
      end

      # Add a custom timing. These are displayed similar to SQL/query time in
      # columns expanding to the right.
      #
      # type        - String counter type. Each distinct type gets its own column.
      # duration_ms - Duration of the call in ms. Either this or a block must be
      #               given but not both.
      #
      # When a block is given, calculate the duration by yielding to the block
      # and keeping a record of its run time.
      #
      # Returns the result of the block, or nil when no block is given.
      def counter(type, duration_ms = nil)
        result = nil
        if block_given?
          start       = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          result      = yield
          duration_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).to_f * 1000
        end
        return result if current.nil? || !request_authorized?
        current.current_timer.add_custom(type, duration_ms, current.page_struct)
        result
      end

      private

      def clean_method_name(method)
        method.to_s.gsub(/[\?\!]/, "")
      end
    end
  end
end
