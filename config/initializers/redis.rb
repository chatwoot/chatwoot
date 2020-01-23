uri = URI.parse(ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379'))
redis = Rails.env.test? ? MockRedis.new : Redis.new(url: uri)
Nightfury.redis = Redis::Namespace.new('reports', redis: redis)

# Alfred - Used currently for round robin and conversation emails.
# Add here as you use it for more features
$alfred = Redis::Namespace.new('alfred', redis: redis, warning: true)
