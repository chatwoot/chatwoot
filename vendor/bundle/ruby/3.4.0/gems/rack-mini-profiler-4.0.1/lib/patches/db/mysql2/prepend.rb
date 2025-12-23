# frozen_string_literal: true

class Mysql2::Result
  module MiniProfiler
    def each(*args, &blk)
      return super unless defined?(@miniprofiler_sql_id)

      start        = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result       = super
      elapsed_time = SqlPatches.elapsed_time(start)

      @miniprofiler_sql_id.report_reader_duration(elapsed_time)
      result
    end
  end

  prepend MiniProfiler
end

class Mysql2::Client
  module MiniProfiler
    def query(*args, &blk)
      return super unless SqlPatches.should_measure?

      result, record = SqlPatches.record_sql(args[0]) do
        super
      end
      result.instance_variable_set("@miniprofiler_sql_id", record) if result
      result
    end
  end

  prepend MiniProfiler
end
