# frozen_string_literal: true

module Sidekiq
  # Server-side middleware must import this Module in order
  # to get access to server resources during `call`.
  module ServerMiddleware
    attr_accessor :config
    def redis_pool
      config.redis_pool
    end

    def logger
      config.logger
    end

    def redis(&block)
      config.redis(&block)
    end
  end

  # no difference for now
  ClientMiddleware = ServerMiddleware
end
