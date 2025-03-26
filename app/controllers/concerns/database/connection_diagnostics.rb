module Database::ConnectionDiagnostics
  extend ActiveSupport::Concern
  include Database::QueryInspection
  include Database::QueryLogging

  private

  def log_connection_pool_stats(connection_pool)
    {
      pool_size: connection_pool.size,
      active_connections: connection_pool.connections.count(&:in_use?),
      total_connections: connection_pool.connections.count,
      waiting_threads: connection_pool.num_waiting_in_queue,
      checkout_timeout: connection_pool.checkout_timeout
    }
  end

  def connection_status_sql
    <<~SQL.squish
      SELECT count(*) as connection_count, state#{' '}
      FROM pg_stat_activity#{' '}
      GROUP BY state;
    SQL
  end

  def fetch_connection_diagnostics
    {
      active_queries: fetch_active_queries,
      locked_queries: fetch_locked_queries,
      connection_status: ActiveRecord::Base.connection.execute(connection_status_sql).to_a
    }
  rescue StandardError => e
    Rails.logger.error "Error fetching active query data: #{e.message}"
    { active_queries: [], locked_queries: [] }
  end

  def caller_info(exception)
    {
      process_id: Process.pid,
      thread_id: Thread.current.object_id,
      backtrace: exception.backtrace&.first(15) || []
    }
  end

  def log_timeout_error(exception, connection_info)
    Rails.logger.error "ActiveRecord::ConnectionTimeoutError: #{exception.message}"
    Rails.logger.error "Connection Pool Stats: #{connection_info.except(:active_queries, :locked_queries).inspect}"
    log_active_queries(connection_info[:active_queries])
    log_locked_queries(connection_info[:locked_queries])
  end
end
