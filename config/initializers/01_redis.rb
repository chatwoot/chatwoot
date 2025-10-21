# TODO: Phase out the custom ConnectionPool wrappers ($alfred / $velma),
# switch to plain Redis clients here and let Rails 7.1+ handle pooling
# via `pool:` in RedisCacheStore (see rack_attack initializer).

# Alfred
# Add here as you use it for more features
# Used for Round Robin, Conversation Emails & Online Presence
$alfred = ConnectionPool.new(size: 5, timeout: 1) do
  redis = Rails.env.test? ? MockRedis.new : Redis.new(Redis::Config.app)
  Redis::Namespace.new('alfred', redis: redis, warning: true)
end

# Velma : Determined protector
# used in rack attack
$velma = ConnectionPool.new(size: 5, timeout: 1) do
  config = Rails.env.test? ? MockRedis.new : Redis.new(Redis::Config.app)
  Redis::Namespace.new('velma', redis: config, warning: true)
end
