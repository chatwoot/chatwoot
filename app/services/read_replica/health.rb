class ReadReplica::Health
  Status = Data.define(:healthy, :lag_seconds, :checked_at)
  PRIMARY_LSN_QUERY = 'SELECT pg_current_wal_lsn()'.freeze
  # Replay timestamps age while an idle replica is fully caught up. Compare WAL positions first,
  # then use the last replay timestamp only while the replica is actually behind.
  HEALTH_QUERY = <<~SQL.squish.freeze
    SELECT pg_is_in_recovery() AS in_recovery,
           CASE
             WHEN pg_last_wal_replay_lsn() >= :primary_lsn::pg_lsn THEN 0
             ELSE EXTRACT(EPOCH FROM clock_timestamp() - pg_last_xact_replay_timestamp())
           END AS lag_seconds
  SQL

  class << self
    def status
      return @status if fresh?

      mutex.synchronize do
        return @status if fresh?

        @status = fetch_status
      end
    end

    def reset!
      mutex.synchronize { @status = nil }
    end

    private

    def fresh?
      return false unless @status

      monotonic_time - @status.checked_at < ReadReplica::Configuration.health_cache_ttl.to_f
    end

    def fetch_status
      primary_lsn = ApplicationRecord.connected_to(role: :writing) do
        ApplicationRecord.connection.select_value(PRIMARY_LSN_QUERY)
      end

      result = ApplicationRecord.connected_to(role: :reading, prevent_writes: true) do
        ApplicationRecord.connection.select_one(health_query(primary_lsn))
      end

      in_recovery = ActiveModel::Type::Boolean.new.cast(result['in_recovery'])
      lag_seconds = result['lag_seconds']&.to_f
      Status.new(healthy: in_recovery && lag_seconds.present?, lag_seconds: lag_seconds, checked_at: monotonic_time)
    rescue StandardError => e
      Rails.logger.warn("Read replica health check failed: #{e.class}: #{e.message}")
      Status.new(healthy: false, lag_seconds: nil, checked_at: monotonic_time)
    end

    def health_query(primary_lsn)
      ApplicationRecord.sanitize_sql_array([HEALTH_QUERY, { primary_lsn: primary_lsn }])
    end

    def mutex
      @mutex ||= Mutex.new
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
