# frozen_string_literal: true

class ActiveRecord::Result
  alias_method :each_without_profiling, :each
  def each(&blk)
    return each_without_profiling(&blk) unless defined?(@miniprofiler_sql_id)

    start        = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result       = each_without_profiling(&blk)
    elapsed_time = SqlPatches.elapsed_time(start)
    @miniprofiler_sql_id.report_reader_duration(elapsed_time)

    result
  end
end

class ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter
  SCHEMA_QUERY_TYPES = ["Sequence", "Primary Key", "Primary Key Trigger", nil].freeze

  alias_method :execute_without_profiling, :execute
  def execute(sql, name = nil)
    mp_profile_sql(sql, name) { execute_without_profiling(sql, name) }
  end

  alias_method :exec_query_without_profiling, :exec_query
  def exec_query(sql, name = 'SQL', binds = [])
    mp_profile_sql(sql, name) { exec_query_without_profiling(sql, name, binds) }
  end

  alias_method :exec_insert_without_profiling, :exec_insert
  def exec_insert(sql, name, binds, pk = nil, sequence_name = nil)
    mp_profile_sql(sql, name) { exec_insert_without_profiling(sql, name, binds, pk, sequence_name) }
  end

  alias_method :exec_update_without_profiling, :exec_update
  def exec_update(sql, name, binds)
    mp_profile_sql(sql, name) { exec_update_without_profiling(sql, name, binds) }
  end

  # See oracle-enhanced/lib/active_record/connection_adapters/oracle_enhanced_database_statements.rb:183
  # where the exec delete method is aliased in the same way. We just have to do it again here to make sure
  # the new exec_delete alias is linked to our profiling-enabled version.
  alias :exec_delete :exec_update

  private

  def mp_profile_sql(sql, name, &blk)
    return yield unless mp_should_measure?(name)

    start        = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result       = yield
    elapsed_time = SqlPatches.elapsed_time(start)
    record       = ::Rack::MiniProfiler.record_sql(sql, elapsed_time)

    # Some queries return the row count as a Fixnum and will be frozen, don't save a record
    # for those.
    result.instance_variable_set("@miniprofiler_sql_id", record) if (result && !result.frozen?)

    result
  end

  # Only measure when profiling is enabled
  # When skip_schema_queries is set to true, it will ignore any query of the types
  # in the schema_query_types array
  def mp_should_measure?(name)
    return false unless SqlPatches.should_measure?

    !(Rack::MiniProfiler.config.skip_schema_queries && SCHEMA_QUERY_TYPES.include?(name))
  end
end
