# TODO: Phase out the custom ConnectionPool wrappers ($alfred / $velma),
# switch to plain Redis clients here and let Rails 7.1+ handle pooling
# via `pool:` in RedisCacheStore (see rack_attack initializer).

# Require mock_redis for test environment if available (only if no Redis URL is configured)
if Rails.env.test? && ENV['REDIS_URL'].blank?
  begin
    require 'mock_redis'
  rescue LoadError
    # mock_redis not available, will use real Redis
  end
end

# Helper method to get Redis client
# Uses MockRedis in test only if no Redis URL is configured and MockRedis is available
# Otherwise uses real Redis (even in test environment if REDIS_URL is set)
def get_redis_client
  if Rails.env.test? && ENV['REDIS_URL'].blank? && defined?(MockRedis)
    MockRedis.new
  else
    Redis.new(Redis::Config.app)
  end
end

# Alfred
# Add here as you use it for more features
# Used for Round Robin, Conversation Emails & Online Presence
$alfred = ConnectionPool.new(size: 5, timeout: 1) do
  redis = get_redis_client
  Redis::Namespace.new('alfred', redis: redis, warning: true)
end

# Velma : Determined protector
# used in rack attack
$velma = ConnectionPool.new(size: 5, timeout: 1) do
  config = get_redis_client
  Redis::Namespace.new('velma', redis: config, warning: true)
end
