# frozen_string_literal: true

module SidekiqAlive
  module Redis
    class << self
      def adapter(capsule = nil)
        Helpers.sidekiq_7 ? Redis::RedisClientGem.new(capsule) : Redis::RedisGem.new
      end
    end
  end
end

require_relative "redis/base"
require_relative "redis/redis_client_gem"
require_relative "redis/redis_gem"
