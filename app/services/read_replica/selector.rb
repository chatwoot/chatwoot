class ReadReplica::Selector
  Selection = Data.define(:role, :reason, :lag_seconds) do
    def reader?
      role == :reading
    end
  end

  def initialize(actor_key:, max_lag:)
    @actor_key = actor_key
    @max_lag = max_lag.to_f
  end

  def select
    return selection(:writing, :disabled) unless ReadReplica::Configuration.enabled?
    return selection(:writing, :writer_sticky) if ReadReplica::WriterStickiness.sticky?(@actor_key)

    health = ReadReplica::Health.status
    return selection(:writing, :unhealthy, health.lag_seconds) unless health.healthy
    return selection(:writing, :lag_exceeded, health.lag_seconds) if health.lag_seconds > @max_lag

    selection(:reading, :eligible, health.lag_seconds)
  end

  private

  def selection(role, reason, lag_seconds = nil)
    Selection.new(role: role, reason: reason, lag_seconds: lag_seconds)
  end
end
