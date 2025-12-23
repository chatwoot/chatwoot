# frozen_string_literal: true

class RSolr::Connection
  alias_method :execute_without_profiling, :execute
  def execute_with_profiling(client, request_context)
    return execute_without_profiling(client, request_context) unless SqlPatches.should_measure?

    start        = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result       = execute_without_profiling(client, request_context)
    elapsed_time = SqlPatches.elapsed_time(start)

    data = "#{request_context[:method].upcase} #{request_context[:uri]}".dup
    if (request_context[:method] == :post) && request_context[:data]
      if request_context[:headers].include?("Content-Type") && (request_context[:headers]["Content-Type"] == "text/xml")
        # it's xml, unescaping isn't needed
        data << "\n#{request_context[:data]}"
      else
        data << "\n#{Rack::Utils.unescape(request_context[:data])}"
      end
    end
    ::Rack::MiniProfiler.record_sql(data, elapsed_time)

    result
  end
  alias_method :execute, :execute_with_profiling
end
