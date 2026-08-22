module Redis::Config
  DEFAULT_SENTINEL_PORT ||= '26379'.freeze
  class << self
    def app
      config
    end

    def config
      @config ||= sentinel? ? sentinel_config : base_config
    end

    def base_config
      {
        url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379'),
        password: ENV.fetch('REDIS_PASSWORD', nil).presence,
        ssl_params: { verify_mode: Chatwoot.redis_ssl_verify_mode },
        reconnect_attempts: 2,
        # redis-client (used by Sidekiq/ActionCable) honours `read_timeout`/
        # `connect_timeout`, not the legacy `timeout` key. Redis periodically
        # stalls for several seconds under Docker Desktop (volume I/O / CPU
        # pauses), which made every Sidekiq worker hit the 3s default and log
        # `RedisClient::ReadTimeoutError: Waited 3 seconds`. Bump this above
        # the observed stall so blocking `brpop` calls complete instead.
        read_timeout: ENV.fetch('REDIS_READ_TIMEOUT', 15).to_i,
        connect_timeout: ENV.fetch('REDIS_CONNECT_TIMEOUT', 5).to_i,
        timeout: 1
      }
    end

    def sentinel?
      ENV.fetch('REDIS_SENTINELS', nil).presence
    end

    def sentinel_url_config(sentinel_url)
      host, port = sentinel_url.split(':').map(&:strip)
      sentinel_url_config = { host: host, port: port || DEFAULT_SENTINEL_PORT }
      password = ENV.fetch('REDIS_SENTINEL_PASSWORD', base_config[:password])
      sentinel_url_config[:password] = password if password.present?
      sentinel_url_config
    end

    def sentinel_config
      redis_sentinels = ENV.fetch('REDIS_SENTINELS', nil)

      # expected format for REDIS_SENTINELS url string is host1:port1, host2:port2
      sentinels = redis_sentinels.split(',').map do |sentinel_url|
        sentinel_url_config(sentinel_url)
      end

      # over-write redis url as redis://:<your-redis-password>@<master-name>/ when using sentinel
      # more at https://github.com/redis/redis-rb/issues/531#issuecomment-263501322
      master = "redis://#{ENV.fetch('REDIS_SENTINEL_MASTER_NAME', 'mymaster')}"

      base_config.merge({ url: master, sentinels: sentinels })
    end
  end
end
