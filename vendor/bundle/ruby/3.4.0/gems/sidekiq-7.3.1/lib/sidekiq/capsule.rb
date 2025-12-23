# frozen_string_literal: true

require "sidekiq/component"

module Sidekiq
  # A Sidekiq::Capsule is the set of resources necessary to
  # process one or more queues with a given concurrency.
  # One "default" Capsule is started but the user may declare additional
  # Capsules in their initializer.
  #
  # This capsule will pull jobs from the "single" queue and process
  # the jobs with one thread, meaning the jobs will be processed serially.
  #
  # Sidekiq.configure_server do |config|
  #   config.capsule("single-threaded") do |cap|
  #     cap.concurrency = 1
  #     cap.queues = %w(single)
  #   end
  # end
  class Capsule
    include Sidekiq::Component
    extend Forwardable

    attr_reader :name
    attr_reader :queues
    attr_accessor :concurrency
    attr_reader :mode
    attr_reader :weights

    def_delegators :@config, :[], :[]=, :fetch, :key?, :has_key?, :merge!, :dig

    def initialize(name, config)
      @name = name
      @config = config
      @queues = ["default"]
      @weights = {"default" => 0}
      @concurrency = config[:concurrency]
      @mode = :strict
    end

    def fetcher
      @fetcher ||= begin
        inst = (config[:fetch_class] || Sidekiq::BasicFetch).new(self)
        inst.setup(config[:fetch_setup]) if inst.respond_to?(:setup)
        inst
      end
    end

    def stop
      fetcher&.bulk_requeue([])
    end

    # Sidekiq checks queues in three modes:
    # - :strict - all queues have 0 weight and are checked strictly in order
    # - :weighted - queues have arbitrary weight between 1 and N
    # - :random - all queues have weight of 1
    def queues=(val)
      @weights = {}
      @queues = Array(val).each_with_object([]) do |qstr, memo|
        arr = qstr
        arr = qstr.split(",") if qstr.is_a?(String)
        name, weight = arr
        @weights[name] = weight.to_i
        [weight.to_i, 1].max.times do
          memo << name
        end
      end
      @mode = if @weights.values.all?(&:zero?)
        :strict
      elsif @weights.values.all? { |x| x == 1 }
        :random
      else
        :weighted
      end
    end

    # Allow the middleware to be different per-capsule.
    # Avoid if possible and add middleware globally so all
    # capsules share the same chains. Easier to debug that way.
    def client_middleware
      @client_chain ||= config.client_middleware.copy_for(self)
      yield @client_chain if block_given?
      @client_chain
    end

    def server_middleware
      @server_chain ||= config.server_middleware.copy_for(self)
      yield @server_chain if block_given?
      @server_chain
    end

    def redis_pool
      Thread.current[:sidekiq_redis_pool] || local_redis_pool
    end

    def local_redis_pool
      # connection pool is lazy, it will not create connections unless you actually need them
      # so don't be skimpy!
      @redis ||= config.new_redis_pool(@concurrency, name)
    end

    def redis
      raise ArgumentError, "requires a block" unless block_given?
      redis_pool.with do |conn|
        retryable = true
        begin
          yield conn
        rescue RedisClientAdapter::BaseError => ex
          # 2550 Failover can cause the server to become a replica, need
          # to disconnect and reopen the socket to get back to the primary.
          # 4495 Use the same logic if we have a "Not enough replicas" error from the primary
          # 4985 Use the same logic when a blocking command is force-unblocked
          # The same retry logic is also used in client.rb
          if retryable && ex.message =~ /READONLY|NOREPLICAS|UNBLOCKED/
            conn.close
            retryable = false
            retry
          end
          raise
        end
      end
    end

    def lookup(name)
      config.lookup(name)
    end

    def logger
      config.logger
    end
  end
end
