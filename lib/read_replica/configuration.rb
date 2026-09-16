module ReadReplica::Configuration
  REQUIRED_ENV_KEYS = %w[
    POSTGRES_REPLICA_HOST
    POSTGRES_REPLICA_DATABASE
    POSTGRES_REPLICA_USERNAME
  ].freeze

  class << self
    def enabled?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch('POSTGRES_REPLICA_ENABLED', false))
    end

    def health_cache_ttl
      ENV.fetch('POSTGRES_REPLICA_HEALTH_CACHE_SECONDS', 5).to_f.seconds
    end

    def writer_stickiness_ttl
      ENV.fetch('POSTGRES_REPLICA_WRITER_STICKINESS_SECONDS', 60).to_i.seconds
    end

    def validate!
      return unless enabled?

      missing_keys = REQUIRED_ENV_KEYS.reject { |key| ENV[key].present? }
      return if missing_keys.empty?

      raise KeyError, "Missing read replica configuration: #{missing_keys.join(', ')}"
    end
  end
end
