module Redis::Config
  DEFAULT_SENTINEL_PORT = 26_379

  BASE_CONFIG = begin
    config = {
      url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379'),
      password: ENV.fetch('REDIS_PASSWORD', nil).presence
    }

    if ENV['REDIS_SENTINELS'].presence
      # expected format for REDIS_SENTINELS url string is host1:port1, host2:port2
      sentinels = ENV['REDIS_SENTINELS'].split(',').map do |sentinel_url|
        host, port = sentinel_url.split(':').map(&:strip)
        { host: host, port: port || DEFAULT_SENTINEL_PORT, password: config[:password] }
      end

      master_name = ENV.fetch('REDIS_SENTINEL_MASTER_NAME', 'mymaster')
      # over-write redis url as redis://:<your-redis-password>@<master-name>/ when using sentinel
      # more at https://github.com/redis/redis-rb/issues/531#issuecomment-263501322
      config[:url] = "redis://#{master_name}"
      config[:sentinels] = sentinels
    end

    config
  end.freeze

  class << self
    def app
      BASE_CONFIG
    end

    def sidekiq
      BASE_CONFIG.merge(size: 25)
    end
  end
end
