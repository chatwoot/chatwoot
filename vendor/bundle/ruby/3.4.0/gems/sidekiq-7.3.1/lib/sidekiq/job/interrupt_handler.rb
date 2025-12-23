# frozen_string_literal: true

module Sidekiq
  module Job
    class InterruptHandler
      include Sidekiq::ServerMiddleware

      def call(instance, hash, queue)
        yield
      rescue Interrupted
        logger.debug "Interrupted, re-queueing..."
        c = Sidekiq::Client.new
        c.push(hash)
        raise Sidekiq::JobRetry::Skip
      end
    end
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Job::InterruptHandler
  end
end
