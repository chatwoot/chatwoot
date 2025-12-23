# frozen_string_literal: true

require "set"
require "redis_client"
require "redis_client/decorator"

module Sidekiq
  class RedisClientAdapter
    BaseError = RedisClient::Error
    CommandError = RedisClient::CommandError

    # You can add/remove items or clear the whole thing if you don't want deprecation warnings.
    DEPRECATED_COMMANDS = %i[rpoplpush zrangebyscore zrevrange zrevrangebyscore getset hmset setex setnx].to_set

    module CompatMethods
      def info
        @client.call("INFO") { |i| i.lines(chomp: true).map { |l| l.split(":", 2) }.select { |l| l.size == 2 }.to_h }
      end

      def evalsha(sha, keys, argv)
        @client.call("EVALSHA", sha, keys.size, *keys, *argv)
      end

      # this is the set of Redis commands used by Sidekiq. Not guaranteed
      # to be comprehensive, we use this as a performance enhancement to
      # avoid calling method_missing on most commands
      USED_COMMANDS = %w[bitfield bitfield_ro del exists expire flushdb
        get hdel hget hgetall hincrby hlen hmget hset hsetnx incr incrby
        lindex llen lmove lpop lpush lrange lrem mget mset ping pttl
        publish rpop rpush sadd scard script set sismember smembers
        srem ttl type unlink zadd zcard zincrby zrange zrem
        zremrangebyrank zremrangebyscore]

      USED_COMMANDS.each do |name|
        define_method(name) do |*args, **kwargs|
          @client.call(name, *args, **kwargs)
        end
      end

      private

      # this allows us to use methods like `conn.hmset(...)` instead of having to use
      # redis-client's native `conn.call("hmset", ...)`
      def method_missing(*args, &block)
        warn("[sidekiq#5788] Redis has deprecated the `#{args.first}`command, called at #{caller(1..1)}") if DEPRECATED_COMMANDS.include?(args.first)
        @client.call(*args, *block)
      end
      ruby2_keywords :method_missing if respond_to?(:ruby2_keywords, true)

      def respond_to_missing?(name, include_private = false)
        super # Appease the linter. We can't tell what is a valid command.
      end
    end

    CompatClient = RedisClient::Decorator.create(CompatMethods)

    class CompatClient
      def config
        @client.config
      end
    end

    def initialize(options)
      opts = client_opts(options)
      @config = if opts.key?(:sentinels)
        RedisClient.sentinel(**opts)
      elsif opts.key?(:nodes)
        # Sidekiq does not support Redis clustering but Sidekiq Enterprise's
        # rate limiters are cluster-safe so we can scale to millions
        # of rate limiters using a Redis cluster. This requires the
        # `redis-cluster-client` gem.
        # Sidekiq::Limiter.redis = { nodes: [...] }
        RedisClient.cluster(**opts)
      else
        RedisClient.config(**opts)
      end
    end

    def new_client
      CompatClient.new(@config.new_client)
    end

    private

    def client_opts(options)
      opts = options.dup

      if opts[:namespace]
        raise ArgumentError, "Your Redis configuration uses the namespace '#{opts[:namespace]}' but this feature is no longer supported in Sidekiq 7+. See https://github.com/sidekiq/sidekiq/blob/main/docs/7.0-Upgrade.md#redis-namespace."
      end

      opts.delete(:size)
      opts.delete(:pool_timeout)

      if opts[:network_timeout]
        opts[:timeout] = opts[:network_timeout]
        opts.delete(:network_timeout)
      end

      opts[:name] = opts.delete(:master_name) if opts.key?(:master_name)
      opts[:role] = opts[:role].to_sym if opts.key?(:role)
      opts[:driver] = opts[:driver].to_sym if opts.key?(:driver)

      # Issue #3303, redis-rb will silently retry an operation.
      # This can lead to duplicate jobs if Sidekiq::Client's LPUSH
      # is performed twice but I believe this is much, much rarer
      # than the reconnect silently fixing a problem; we keep it
      # on by default.
      opts[:reconnect_attempts] ||= 1

      opts
    end
  end
end
