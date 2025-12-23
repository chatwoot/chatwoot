# frozen_string_literal: true

class PG::Result
  module MiniProfiler
    def values(*args, &blk)
      return super unless defined?(@miniprofiler_sql_id)
      mp_report_sql do
        super
      end
    end

    def each(*args, &blk)
      return super unless defined?(@miniprofiler_sql_id)
      mp_report_sql do
        super
      end
    end

    def mp_report_sql(&block)
      start        = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result       = yield
      elapsed_time = SqlPatches.elapsed_time(start)
      @miniprofiler_sql_id.report_reader_duration(elapsed_time)
      result
    end
  end

  prepend MiniProfiler
end

class PG::Connection
  module MiniProfiler
    def prepare(*args, &blk)
      # we have no choice but to do this here,
      # if we do the check for profiling first, our cache may miss critical stuff

      @prepare_map ||= {}
      @prepare_map[args[0]] = args[1]
      # dont leak more than 10k ever
      @prepare_map = {} if @prepare_map.length > 1000

      return super unless SqlPatches.should_measure?
      super
    end

    def exec(*args, &blk)
      return super unless SqlPatches.should_measure?

      start        = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result       = super
      elapsed_time = SqlPatches.elapsed_time(start)
      record       = ::Rack::MiniProfiler.record_sql(args[0], elapsed_time)
      result.instance_variable_set("@miniprofiler_sql_id", record) if result

      result
    end

    if Gem::Version.new(PG::VERSION) >= Gem::Version.new("1.1.0")
      def exec_params(*args, &blk)
        return super unless SqlPatches.should_measure?

        start        = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result       = super
        elapsed_time = SqlPatches.elapsed_time(start)
        record       = ::Rack::MiniProfiler.record_sql(args[0], elapsed_time)
        result.instance_variable_set("@miniprofiler_sql_id", record) if result

        result
      end
    end

    def exec_prepared(*args, &blk)
      return super unless SqlPatches.should_measure?

      start        = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result       = super
      elapsed_time = SqlPatches.elapsed_time(start)
      mapped       = args[0]
      mapped       = @prepare_map[mapped] || args[0] if @prepare_map
      record       = ::Rack::MiniProfiler.record_sql(mapped, elapsed_time)
      result.instance_variable_set("@miniprofiler_sql_id", record) if result

      result
    end

    def send_query_prepared(*args, &blk)
      return super unless SqlPatches.should_measure?

      start        = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result       = super
      elapsed_time = SqlPatches.elapsed_time(start)
      mapped       = args[0]
      mapped       = @prepare_map[mapped] || args[0] if @prepare_map
      record       = ::Rack::MiniProfiler.record_sql(mapped, elapsed_time)
      result.instance_variable_set("@miniprofiler_sql_id", record) if result

      result
    end

    def async_exec(*args, &blk)
      return super unless SqlPatches.should_measure?

      start        = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result       = super
      elapsed_time = SqlPatches.elapsed_time(start)
      record       = ::Rack::MiniProfiler.record_sql(args[0], elapsed_time)
      result.instance_variable_set("@miniprofiler_sql_id", record) if result

      result
    end
  end

  prepend MiniProfiler
  alias_method :query, :exec
end
