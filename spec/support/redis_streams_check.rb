# frozen_string_literal: true

# The connector transport is Redis Streams, and MockRedis (which the app's own pools use
# under test) implements none of XREADGROUP, XAUTOCLAIM, BLPOP or EVAL. The specs tagged
# :redis_streams therefore open their own connection to the real Redis the test
# environment points at, each under a prefix of its own, and clean up after themselves.
#
# The check runs once per tagged context so a missing Redis reads as one clear message
# instead of a connection error inside every example.
RSpec.configure do |config|
  config.before(:context, :redis_streams) do
    redis = Redis.new(Redis::Config.app)
    redis.ping
  rescue StandardError => e
    raise "Redis is not reachable at #{Redis::Config.app[:url]}, which the :redis_streams specs need: #{e.message}"
  ensure
    redis&.close
  end
end
