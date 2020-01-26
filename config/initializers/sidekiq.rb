sidekiq_redis_config = {
    url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379'),
    password: ENV.fetch('REDIS_PASSWORD', nil)
}
Sidekiq.configure_client do |config|
    config.redis = sidekiq_redis_config
end

Sidekiq.configure_server do |config|
    config.redis = sidekiq_redis_config
end
