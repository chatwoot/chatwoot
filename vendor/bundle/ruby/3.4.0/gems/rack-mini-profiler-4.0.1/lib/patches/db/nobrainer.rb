# frozen_string_literal: true

class Rack::MiniProfiler::NoBrainerProfiler

  def on_query(env)
    if SqlPatches.should_measure?
      not_indexed = env[:criteria] && env[:criteria].where_present? &&
                        !env[:criteria].where_indexed? &&
                        !env[:criteria].model.try(:perf_warnings_disabled)

      query = "".dup

      # per-model/query database overrides
      query << "[#{env[:options][:db]}] " if env[:options][:db]

      # "read", "write" prefix
      # query << "(#{NoBrainer::RQL.type_of(env[:query]).to_s}) "

      query << "NOT USING INDEX: " if not_indexed
      query << env[:query].inspect.delete("\n").gsub(/ +/, ' ') + " "

      if env[:exception]
        query << "exception: #{env[:exception].class} #{env[:exception].message.split("\n").first} "
      end

      ::Rack::MiniProfiler.record_sql query.strip, env[:duration] * 1000.0
    end
  end

  NoBrainer::Profiler.register self.new
end
