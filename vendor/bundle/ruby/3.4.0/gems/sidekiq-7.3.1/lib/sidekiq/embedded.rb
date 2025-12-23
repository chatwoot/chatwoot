# frozen_string_literal: true

require "sidekiq/component"
require "sidekiq/launcher"
require "sidekiq/metrics/tracking"

module Sidekiq
  class Embedded
    include Sidekiq::Component

    def initialize(config)
      @config = config
    end

    def run
      housekeeping
      fire_event(:startup, reverse: false, reraise: true)
      @launcher = Sidekiq::Launcher.new(@config, embedded: true)
      @launcher.run
      sleep 0.2 # pause to give threads time to spin up

      logger.info "Sidekiq running embedded, total process thread count: #{Thread.list.size}"
      logger.debug { Thread.list.map(&:name) }
    end

    def quiet
      @launcher&.quiet
    end

    def stop
      @launcher&.stop
    end

    private

    def housekeeping
      logger.info "Running in #{RUBY_DESCRIPTION}"
      logger.info Sidekiq::LICENSE
      logger.info "Upgrade to Sidekiq Pro for more features and support: https://sidekiq.org" unless defined?(::Sidekiq::Pro)

      # touch the connection pool so it is created before we
      # fire startup and start multithreading.
      info = config.redis_info
      ver = Gem::Version.new(info["redis_version"])
      raise "You are connecting to Redis #{ver}, Sidekiq requires Redis 6.2.0 or greater" if ver < Gem::Version.new("6.2.0")

      maxmemory_policy = info["maxmemory_policy"]
      if maxmemory_policy != "noeviction"
        logger.warn <<~EOM


          WARNING: Your Redis instance will evict Sidekiq data under heavy load.
          The 'noeviction' maxmemory policy is recommended (current policy: '#{maxmemory_policy}').
          See: https://github.com/sidekiq/sidekiq/wiki/Using-Redis#memory

        EOM
      end

      logger.debug { "Client Middleware: #{@config.default_capsule.client_middleware.map(&:klass).join(", ")}" }
      logger.debug { "Server Middleware: #{@config.default_capsule.server_middleware.map(&:klass).join(", ")}" }
    end
  end
end
