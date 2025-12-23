# frozen_string_literal: true

require "forwardable"

require "set"
require "sidekiq/redis_connection"

module Sidekiq
  # Sidekiq::Config represents the global configuration for an instance of Sidekiq.
  class Config
    extend Forwardable

    DEFAULTS = {
      labels: Set.new,
      require: ".",
      environment: nil,
      concurrency: 5,
      timeout: 25,
      poll_interval_average: nil,
      average_scheduled_poll_interval: 5,
      on_complex_arguments: :raise,
      iteration: {
        max_job_runtime: nil,
        retry_backoff: 0
      },
      error_handlers: [],
      death_handlers: [],
      lifecycle_events: {
        startup: [],
        quiet: [],
        shutdown: [],
        # triggers when we fire the first heartbeat on startup OR repairing a network partition
        heartbeat: [],
        # triggers on EVERY heartbeat call, every 10 seconds
        beat: []
      },
      dead_max_jobs: 10_000,
      dead_timeout_in_seconds: 180 * 24 * 60 * 60, # 6 months
      reloader: proc { |&block| block.call },
      backtrace_cleaner: ->(backtrace) { backtrace }
    }

    ERROR_HANDLER = ->(ex, ctx, cfg = Sidekiq.default_configuration) {
      l = cfg.logger
      l.warn(Sidekiq.dump_json(ctx)) unless ctx.empty?
      l.warn("#{ex.class.name}: #{ex.message}")
      unless ex.backtrace.nil?
        backtrace = cfg[:backtrace_cleaner].call(ex.backtrace)
        l.warn(backtrace.join("\n"))
      end
    }

    def initialize(options = {})
      @options = DEFAULTS.merge(options)
      @options[:error_handlers] << ERROR_HANDLER if @options[:error_handlers].empty?
      @directory = {}
      @redis_config = {}
      @capsules = {}
    end

    def_delegators :@options, :[], :[]=, :fetch, :key?, :has_key?, :merge!, :dig
    attr_reader :capsules

    def to_json(*)
      Sidekiq.dump_json(@options)
    end

    # LEGACY: edits the default capsule
    # config.concurrency = 5
    def concurrency=(val)
      default_capsule.concurrency = Integer(val)
    end

    def concurrency
      default_capsule.concurrency
    end

    def total_concurrency
      capsules.each_value.sum(&:concurrency)
    end

    # Edit the default capsule.
    # config.queues = %w( high default low )                 # strict
    # config.queues = %w( high,3 default,2 low,1 )           # weighted
    # config.queues = %w( feature1,1 feature2,1 feature3,1 ) # random
    #
    # With weighted priority, queue will be checked first (weight / total) of the time.
    # high will be checked first (3/6) or 50% of the time.
    # I'd recommend setting weights between 1-10. Weights in the hundreds or thousands
    # are ridiculous and unnecessarily expensive. You can get random queue ordering
    # by explicitly setting all weights to 1.
    def queues=(val)
      default_capsule.queues = val
    end

    def queues
      default_capsule.queues
    end

    def client_middleware
      @client_chain ||= Sidekiq::Middleware::Chain.new(self)
      yield @client_chain if block_given?
      @client_chain
    end

    def server_middleware
      @server_chain ||= Sidekiq::Middleware::Chain.new(self)
      yield @server_chain if block_given?
      @server_chain
    end

    def default_capsule(&block)
      capsule("default", &block)
    end

    # register a new queue processing subsystem
    def capsule(name)
      nm = name.to_s
      cap = @capsules.fetch(nm) do
        cap = Sidekiq::Capsule.new(nm, self)
        @capsules[nm] = cap
      end
      yield cap if block_given?
      cap
    end

    # All capsules must use the same Redis configuration
    def redis=(hash)
      @redis_config = @redis_config.merge(hash)
    end

    def redis_pool
      Thread.current[:sidekiq_redis_pool] || Thread.current[:sidekiq_capsule]&.redis_pool || local_redis_pool
    end

    private def local_redis_pool
      # this is our internal client/housekeeping pool. each capsule has its
      # own pool for executing threads.
      @redis ||= new_redis_pool(10, "internal")
    end

    def new_redis_pool(size, name = "unset")
      # connection pool is lazy, it will not create connections unless you actually need them
      # so don't be skimpy!
      RedisConnection.create({size: size, logger: logger, pool_name: name}.merge(@redis_config))
    end

    def redis_info
      redis do |conn|
        conn.call("INFO") { |i| i.lines(chomp: true).map { |l| l.split(":", 2) }.select { |l| l.size == 2 }.to_h }
      rescue RedisClientAdapter::CommandError => ex
        # 2850 return fake version when INFO command has (probably) been renamed
        raise unless /unknown command/.match?(ex.message)
        {
          "redis_version" => "9.9.9",
          "uptime_in_days" => "9999",
          "connected_clients" => "9999",
          "used_memory_human" => "9P",
          "used_memory_peak_human" => "9P"
        }.freeze
      end
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

    # register global singletons which can be accessed elsewhere
    def register(name, instance)
      @directory[name] = instance
    end

    # find a singleton
    def lookup(name, default_class = nil)
      # JNDI is just a fancy name for a hash lookup
      @directory.fetch(name) do |key|
        return nil unless default_class
        @directory[key] = default_class.new(self)
      end
    end

    ##
    # Death handlers are called when all retries for a job have been exhausted and
    # the job dies.  It's the notification to your application
    # that this job will not succeed without manual intervention.
    #
    # Sidekiq.configure_server do |config|
    #   config.death_handlers << ->(job, ex) do
    #   end
    # end
    def death_handlers
      @options[:death_handlers]
    end

    # How frequently Redis should be checked by a random Sidekiq process for
    # scheduled and retriable jobs. Each individual process will take turns by
    # waiting some multiple of this value.
    #
    # See sidekiq/scheduled.rb for an in-depth explanation of this value
    def average_scheduled_poll_interval=(interval)
      @options[:average_scheduled_poll_interval] = interval
    end

    # Register a proc to handle any error which occurs within the Sidekiq process.
    #
    #   Sidekiq.configure_server do |config|
    #     config.error_handlers << proc {|ex,ctx_hash| MyErrorService.notify(ex, ctx_hash) }
    #   end
    #
    # The default error handler logs errors to @logger.
    def error_handlers
      @options[:error_handlers]
    end

    # Register a block to run at a point in the Sidekiq lifecycle.
    # :startup, :quiet or :shutdown are valid events.
    #
    #   Sidekiq.configure_server do |config|
    #     config.on(:shutdown) do
    #       puts "Goodbye cruel world!"
    #     end
    #   end
    def on(event, &block)
      raise ArgumentError, "Symbols only please: #{event}" unless event.is_a?(Symbol)
      raise ArgumentError, "Invalid event name: #{event}" unless @options[:lifecycle_events].key?(event)
      @options[:lifecycle_events][event] << block
    end

    def logger
      @logger ||= Sidekiq::Logger.new($stdout, level: :info).tap do |log|
        log.level = Logger::INFO
        log.formatter = if ENV["DYNO"]
          Sidekiq::Logger::Formatters::WithoutTimestamp.new
        else
          Sidekiq::Logger::Formatters::Pretty.new
        end
      end
    end

    def logger=(logger)
      if logger.nil?
        self.logger.level = Logger::FATAL
        return
      end

      @logger = logger
    end

    private def parameter_size(handler)
      target = handler.is_a?(Proc) ? handler : handler.method(:call)
      target.parameters.size
    end

    # INTERNAL USE ONLY
    def handle_exception(ex, ctx = {})
      if @options[:error_handlers].size == 0
        p ["!!!!!", ex]
      end
      @options[:error_handlers].each do |handler|
        if parameter_size(handler) == 2
          # TODO Remove in 8.0
          logger.info { "DEPRECATION: Sidekiq exception handlers now take three arguments, see #{handler}" }
          handler.call(ex, {_config: self}.merge(ctx))
        else
          handler.call(ex, ctx, self)
        end
      rescue Exception => e
        l = logger
        l.error "!!! ERROR HANDLER THREW AN ERROR !!!"
        l.error e
        l.error e.backtrace.join("\n") unless e.backtrace.nil?
      end
    end
  end
end
