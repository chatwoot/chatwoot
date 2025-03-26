module Database::QueryInspection
  extend ActiveSupport::Concern

  private

  def active_queries_sql
    <<~SQL.squish
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
  end

  def process_active_query_row(row)
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

  def fetch_active_queries
    query_data = ActiveRecord::Base.connection.execute(active_queries_sql)
    query_data.map { |row| process_active_query_row(row) }
  end

  def locked_queries_sql
    <<~SQL.squish
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
  end

  def process_lock_row(row)
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

  def fetch_locked_queries
    lock_data = ActiveRecord::Base.connection.execute(locked_queries_sql)
    return [] if lock_data.count.zero?

    lock_data.map { |row| process_lock_row(row) }
  end
end
