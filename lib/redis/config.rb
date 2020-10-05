module Redis::Config
  DEFAULT_SENTINEL_PORT = '26379'.freeze
  SIDEKIQ_SIZE = 25

  class << self
    def app
      return BASE_CONFIG if const_defined? 'BASE_CONFIG'

      reload_config
    end

    def sidekiq
      config = begin
        if const_defined? 'BASE_CONFIG'
          BASE_CONFIG
        else
          reload_config
        end
      end
      config.merge(size: SIDEKIQ_SIZE)
    end

    def reload_config
      config = {
        url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379'),
        password: ENV.fetch('REDIS_PASSWORD', nil).presence
      }

      sentinel_string = ENV.fetch('REDIS_SENTINELS', nil)
      if sentinel_string.presence
        # expected format for REDIS_SENTINELS url string is host1:port1, host2:port2
        sentinels = sentinel_string.split(',').map do |sentinel_url|
          host, port = sentinel_url.split(':').map(&:strip)
          { host: host, port: port || DEFAULT_SENTINEL_PORT, password: config[:password] }
        end

        master_name = ENV.fetch('REDIS_SENTINEL_MASTER_NAME', 'mymaster')
        # over-write redis url as redis://:<your-redis-password>@<master-name>/ when using sentinel
        # more at https://github.com/redis/redis-rb/issues/531#issuecomment-263501322
        config[:url] = "redis://#{master_name}"
        config[:sentinels] = sentinels
      end
      send(:remove_const, 'BASE_CONFIG') if const_defined? 'BASE_CONFIG'
      const_set('BASE_CONFIG', config)
      BASE_CONFIG
    end
  end
end
