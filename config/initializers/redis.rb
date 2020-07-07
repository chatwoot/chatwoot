app_redis_config = {
  url: URI.parse(ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379')),
  password: ENV.fetch('REDIS_PASSWORD', nil).presence
}
redis = Rails.env.test? ? MockRedis.new : Redis.new(app_redis_config)

# Alfred
# Add here as you use it for more features
# Used for Round Robin, Conversation Emails & Online Presence
$alfred = Redis::Namespace.new('alfred', redis: redis, warning: true)

# https://github.com/mperham/sidekiq/issues/4591
# TODO once sidekiq remove we can remove this
Redis.exists_returns_integer = false
