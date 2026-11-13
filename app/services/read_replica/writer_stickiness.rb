class ReadReplica::WriterStickiness
  KEY_PREFIX = 'read-replica:writer-sticky'.freeze

  class << self
    def sticky?(actor_key)
      return false if actor_key.blank?

      Redis::Alfred.exists?(redis_key(actor_key))
    rescue Redis::BaseError => e
      Rails.logger.warn("Read replica writer-stickiness lookup failed: #{e.class}: #{e.message}")
      true
    end

    def mark!(actor_key)
      return unless ReadReplica::Configuration.enabled?
      return if actor_key.blank?

      Redis::Alfred.set(redis_key(actor_key), Time.current.to_i, ex: ReadReplica::Configuration.writer_stickiness_ttl.to_i)
    rescue Redis::BaseError => e
      Rails.logger.warn("Read replica writer-stickiness update failed: #{e.class}: #{e.message}")
    end

    private

    def redis_key(actor_key)
      "#{KEY_PREFIX}:#{actor_key}"
    end
  end
end
