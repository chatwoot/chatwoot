# frozen_string_literal: true

class Neo4j::Core::Query
  alias_method :response_without_miniprofiler, :response

  def response
    return @response if @response
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    rval = response_without_miniprofiler
    elapsed_time = SqlPatches.elapsed_time(start)
    Rack::MiniProfiler.record_sql(to_cypher, elapsed_time)
    rval
  end

  alias_method :response_with_miniprofiler, :response
end
