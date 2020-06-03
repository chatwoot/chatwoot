app_redis_config = {
  url: URI.parse(ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379')),
  password: ENV.fetch('REDIS_PASSWORD', nil).presence
}
redis = Rails.env.test? ? MockRedis.new : Redis.new(app_redis_config)

# Alfred - Used currently for round robin and conversation emails.
# Add here as you use it for more features
$alfred = Redis::Namespace.new('alfred', redis: redis, warning: true)
