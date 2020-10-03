app_redis_config = {
  url: URI.parse(ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379')),
  password: ENV.fetch('REDIS_PASSWORD', nil).presence
}

if ENV['REDIS_SENTINELS'].presence
  default_sentinel_port = '26379'
  # expected format for REDIS_SENTINELS url string is host1:port1, host2:port2
  sentinels = ENV['REDIS_SENTINELS'].split(',').map do |sentinel_url|
    host, port = sentinel_url.split(':').map(&:strip)
    { host: host, port: port || default_sentinel_port, password: app_redis_config[:password] }
  end

  master_name = ENV.fetch('REDIS_SENTINEL_MASTER_NAME', 'mymaster')
  # over-write redis url as redis://:<your-redis-password>@<master-name>/ when using sentinel
  # more at https://github.com/redis/redis-rb/issues/531#issuecomment-263501322
  app_redis_config[:url] = URI.parse("redis://#{master_name}")
  app_redis_config[:sentinels] = sentinels
end

redis = Rails.env.test? ? MockRedis.new : Redis.new(app_redis_config)
# Alfred
# Add here as you use it for more features
# Used for Round Robin, Conversation Emails & Online Presence
$alfred = Redis::Namespace.new('alfred', redis: redis, warning: true)

# https://github.com/mperham/sidekiq/issues/4591
# TODO once sidekiq remove we can remove this
Redis.exists_returns_integer = false
