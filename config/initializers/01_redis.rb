Rails.application.reloader.to_prepare do
  # Alfred
  # Add here as you use it for more features
  # Used for Round Robin, Conversation Emails & Online Presence
  $alfred = ConnectionPool.new(size: 5, timeout: 3) do
    redis = Rails.env.test? ? MockRedis.new : Redis.new(Redis::Config.app)
    Redis::Namespace.new('alfred', redis: redis, warning: true)
  end

  # Velma : Determined protector
  # used in rack attack
  $velma = ConnectionPool.new(size: 5, timeout: 3) do
    config = Rails.env.test? ? MockRedis.new : Redis.new(Redis::Config.app)
    Redis::Namespace.new('velma', redis: config, warning: true)
  end
end
