class Captain::OutcomeTrackingHistory
  CACHE_KEY = 'captain:outcome_tracking_started_at:v1'.freeze
  CACHE_TTL = 30.days
  EMPTY_CACHE_TTL = 1.minute

  def self.started_at
    cached = Redis::Alfred.get(CACHE_KEY)
    if cached
      timestamp = JSON.parse(cached)
    else
      timestamp = ConversationOutcome.minimum(:created_at)&.iso8601(6)
      ttl = timestamp ? CACHE_TTL : EMPTY_CACHE_TTL
      Redis::Alfred.set(CACHE_KEY, timestamp.to_json, ex: ttl.to_i)
    end

    Time.iso8601(timestamp) if timestamp
  end
end
