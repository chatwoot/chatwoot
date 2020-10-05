Sidekiq.configure_client do |config|
  config.redis = Redis::Config.sidekiq
end

Sidekiq.configure_server do |config|
  config.redis = Redis::Config.sidekiq
end
