redis = Rails.env.test? ? MockRedis.new : Redis.new(Redis::Config.app)

# Alfred
# Add here as you use it for more features
# Used for Round Robin, Conversation Emails & Online Presence
$alfred = Redis::Namespace.new('alfred', redis: redis, warning: true)

# https://github.com/mperham/sidekiq/issues/4591
# TODO once sidekiq remove we can remove this
Redis.exists_returns_integer = false
