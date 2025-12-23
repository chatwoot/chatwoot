# frozen_string_literal: true

require "connection_pool"
require "uri"
require "sidekiq/redis_client_adapter"

module Sidekiq
  module RedisConnection
    class << self
      def create(options = {})
        symbolized_options = deep_symbolize_keys(options)
        symbolized_options[:url] ||= determine_redis_provider

        logger = symbolized_options.delete(:logger)
        logger&.info { "Sidekiq #{Sidekiq::VERSION} connecting to Redis with options #{scrub(symbolized_options)}" }

        raise "Sidekiq 7+ does not support Redis protocol 2" if symbolized_options[:protocol] == 2

        safe = !!symbolized_options.delete(:cluster_safe)
        raise ":nodes not allowed, Sidekiq is not safe to run on Redis Cluster" if !safe && symbolized_options.key?(:nodes)

        size = symbolized_options.delete(:size) || 5
        pool_timeout = symbolized_options.delete(:pool_timeout) || 1
        pool_name = symbolized_options.delete(:pool_name)

        # Default timeout in redis-client is 1 second, which can be too aggressive
        # if the Sidekiq process is CPU-bound. With 10-15 threads and a thread quantum of 100ms,
        # it can be easy to get the occasional ReadTimeoutError. You can still provide
        # a smaller timeout explicitly:
        #     config.redis = { url: "...", timeout: 1 }
        symbolized_options[:timeout] ||= 3

        redis_config = Sidekiq::RedisClientAdapter.new(symbolized_options)
        ConnectionPool.new(timeout: pool_timeout, size: size, name: pool_name) do
          redis_config.new_client
        end
      end

      private

      def deep_symbolize_keys(object)
        case object
        when Hash
          object.each_with_object({}) do |(key, value), result|
            result[key.to_sym] = deep_symbolize_keys(value)
          end
        when Array
          object.map { |e| deep_symbolize_keys(e) }
        else
          object
        end
      end

      def scrub(options)
        redacted = "REDACTED"

        # Deep clone so we can muck with these options all we want and exclude
        # params from dump-and-load that may contain objects that Marshal is
        # unable to safely dump.
        keys = options.keys - [:logger, :ssl_params]
        scrubbed_options = Marshal.load(Marshal.dump(options.slice(*keys)))
        if scrubbed_options[:url] && (uri = URI.parse(scrubbed_options[:url])) && uri.password
          uri.password = redacted
          scrubbed_options[:url] = uri.to_s
        end
        scrubbed_options[:password] = redacted if scrubbed_options[:password]
        scrubbed_options[:sentinel_password] = redacted if scrubbed_options[:sentinel_password]
        scrubbed_options[:sentinels]&.each do |sentinel|
          if sentinel.is_a?(String)
            if (uri = URI(sentinel)) && uri.password
              uri.password = redacted
              sentinel.replace(uri.to_s)
            end
          elsif sentinel[:password]
            sentinel[:password] = redacted
          end
        end
        scrubbed_options
      end

      def determine_redis_provider
        # If you have this in your environment:
        # MY_REDIS_URL=redis://hostname.example.com:1238/4
        # then set:
        # REDIS_PROVIDER=MY_REDIS_URL
        # and Sidekiq will find your custom URL variable with no custom
        # initialization code at all.
        #
        p = ENV["REDIS_PROVIDER"]
        if p && p =~ /:/
          raise <<~EOM
            REDIS_PROVIDER should be set to the name of the variable which contains the Redis URL, not a URL itself.
            Platforms like Heroku will sell addons that publish a *_URL variable.  You need to tell Sidekiq with REDIS_PROVIDER, e.g.:

            REDISTOGO_URL=redis://somehost.example.com:6379/4
            REDIS_PROVIDER=REDISTOGO_URL
          EOM
        end

        ENV[p.to_s] || ENV["REDIS_URL"]
      end
    end
  end
end
