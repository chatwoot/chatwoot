# Alfred
# Add here as you use it for more features
# Used for Round Robin, Conversation Emails & Online Presence
$alfred = ConnectionPool::Wrapper.new(size: 5, timeout: 3) do
  redis = Rails.env.test? ? MockRedis.new : Redis.new(Redis::Config.app)
  Redis::Namespace.new('alfred', redis: redis, warning: true)
end

# Velma : Determined protector
# used in rack attack
$velma = ConnectionPool::Wrapper.new(size: 5, timeout: 3) do
  redis = Rails.env.test? ? MockRedis.new : Redis.new(Redis::Config.app)
  Redis::Namespace.new('velma', redis: redis, warning: true)
end
