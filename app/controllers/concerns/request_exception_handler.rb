module RequestExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
    rescue_from ActiveRecord::ConnectionTimeoutError, with: :handle_connection_timeout
  end

  private

  def handle_with_exception
    yield
  rescue ActiveRecord::RecordNotFound => e
    log_handled_error(e)
    render_not_found_error('Resource could not be found')
  rescue Pundit::NotAuthorizedError => e
    log_handled_error(e)
    render_unauthorized('You are not authorized to do this action')
  rescue ActionController::ParameterMissing => e
    log_handled_error(e)
    render_could_not_create_error(e.message)
  rescue ActiveRecord::ConnectionTimeoutError => e
    handle_connection_timeout(e)
  ensure
    # to address the thread variable leak issues in Puma/Thin webserver
    Current.reset
  end

  def log_connection_pool_stats(connection_pool)
    {
      pool_size: connection_pool.size,
      active_connections: connection_pool.connections.count(&:in_use?),
      total_connections: connection_pool.connections.count,
      waiting_threads: connection_pool.num_waiting_in_queue,
      checkout_timeout: connection_pool.checkout_timeout
    }
  end

  def fetch_active_queries
    query_data = ActiveRecord::Base.connection.execute(<<~SQL.squish)
      SELECT pid,#{' '}
             now() - pg_stat_activity.query_start AS duration,
             query,
             state,
             wait_event_type,
             wait_event,
             backend_type,
             application_name,
             client_addr,
             usename
      FROM pg_stat_activity#{' '}
      WHERE state <> 'idle'
        AND query NOT ILIKE '%pg_stat_activity%'
      ORDER BY duration DESC;
    SQL

    query_data.map do |row|
      {
        pid: row['pid'],
        duration: row['duration'].to_s,
        state: row['state'],
        query: row['query'],
        wait_event_type: row['wait_event_type'],
        wait_event: row['wait_event'],
        backend_type: row['backend_type'],
        application_name: row['application_name'],
        client_addr: row['client_addr'],
        username: row['usename']
      }
    end
  end

  def fetch_locked_queries
    lock_data = ActiveRecord::Base.connection.execute(<<~SQL.squish)
      SELECT blocked_locks.pid AS blocked_pid,
             blocked_activity.usename AS blocked_user,
             blocking_locks.pid AS blocking_pid,
             blocking_activity.usename AS blocking_user,
             blocked_activity.query AS blocked_statement,
             blocking_activity.query AS blocking_statement,
             now() - blocking_activity.query_start AS blocking_duration
      FROM pg_catalog.pg_locks blocked_locks
      JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
      JOIN pg_catalog.pg_locks blocking_locks#{' '}
          ON blocking_locks.locktype = blocked_locks.locktype
          AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
          AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
          AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
          AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
          AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
          AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
          AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
          AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
          AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
          AND blocking_locks.pid != blocked_locks.pid
      JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
      WHERE NOT blocked_locks.granted;
    SQL

    return [] if lock_data.count.zero?

    lock_data.map do |row|
      {
        blocked_pid: row['blocked_pid'],
        blocked_user: row['blocked_user'],
        blocking_pid: row['blocking_pid'],
        blocking_user: row['blocking_user'],
        blocked_statement: row['blocked_statement'],
        blocking_statement: row['blocking_statement'],
        blocking_duration: row['blocking_duration'].to_s
      }
    end
  end

  def log_active_queries(active_queries)
    if active_queries.any?
      Rails.logger.error "Active Database Queries (#{active_queries.count}):"
      active_queries.each_with_index do |query_info, index|
        Rails.logger.error "Query ##{index + 1} [PID: #{query_info[:pid]}] [Duration: #{query_info[:duration]}] [State: #{query_info[:state]}]:"
        Rails.logger.error "App: #{query_info[:application_name]} User: #{query_info[:username]} Client: #{query_info[:client_addr]}"
        Rails.logger.error "Waiting: #{query_info[:wait_event_type]} / #{query_info[:wait_event]}" if query_info[:wait_event_type].present?
        Rails.logger.error query_info[:query]
      end
    else
      Rails.logger.error 'No active queries found or unable to retrieve query information'
    end
  end

  def log_locked_queries(locked_queries)
    return unless locked_queries.present?

    Rails.logger.error "Locked Queries (#{locked_queries.count}):"
    locked_queries.each_with_index do |lock_info, index|
      Rails.logger.error "Lock ##{index + 1}: PID #{lock_info[:blocked_pid]} blocked by PID #{lock_info[:blocking_pid]}"
      Rails.logger.error "Duration: #{lock_info[:blocking_duration]}"
      Rails.logger.error "Blocked query: #{lock_info[:blocked_statement]}"
      Rails.logger.error "Blocking query: #{lock_info[:blocking_statement]}"
    end
  end

  def handle_connection_timeout(exception)
    connection_pool = ActiveRecord::Base.connection_pool
    connection_info = log_connection_pool_stats(connection_pool)
    active_queries = []
    locked_queries = []

    begin
      active_queries = fetch_active_queries
      locked_queries = fetch_locked_queries

      connection_info[:connection_status] = ActiveRecord::Base.connection.execute(<<~SQL.squish).to_a
        SELECT count(*) as connection_count, state#{' '}
        FROM pg_stat_activity#{' '}
        GROUP BY state;
      SQL
    rescue StandardError => e
      Rails.logger.error "Error fetching active query data: #{e.message}"
    end

    connection_info[:active_queries] = active_queries
    connection_info[:locked_queries] = locked_queries

    # Get the process/thread ID that's experiencing the timeout
    connection_info[:caller_info] = {
      process_id: Process.pid,
      thread_id: Thread.current.object_id,
      backtrace: exception.backtrace&.first(15) || []
    }

    # Log details about the error
    Rails.logger.error "ActiveRecord::ConnectionTimeoutError: #{exception.message}"
    Rails.logger.error "Connection Pool Stats: #{connection_info.except(:active_queries, :locked_queries).inspect}"

    log_active_queries(active_queries)
    log_locked_queries(locked_queries)

    # Report to exception tracker with additional context
    ChatwootExceptionTracker.new(
      exception,
      user: Current.user,
      account: Current.account,
      additional_context: { connection_info: connection_info }
    ).capture_exception

    render_service_unavailable('Database connection timeout. Please try again later.')
  end

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end

  def render_not_found_error(message)
    render json: { error: message }, status: :not_found
  end

  def render_could_not_create_error(message)
    render json: { error: message }, status: :unprocessable_entity
  end

  def render_payment_required(message)
    render json: { error: message }, status: :payment_required
  end

  def render_internal_server_error(message)
    render json: { error: message }, status: :internal_server_error
  end

  def render_service_unavailable(message)
    render json: { error: message }, status: :service_unavailable
  end

  def render_record_invalid(exception)
    log_handled_error(exception)
    render json: {
      message: exception.record.errors.full_messages.join(', '),
      attributes: exception.record.errors.attribute_names
    }, status: :unprocessable_entity
  end

  def render_error_response(exception)
    log_handled_error(exception)
    render json: exception.to_hash, status: exception.http_status
  end

  def log_handled_error(exception)
    logger.info("Handled error: #{exception.inspect}")
  end
end
