# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation::Redis
  class Constants
    PRODUCT_NAME = 'Redis'
    CONNECT = 'connect'
    UNKNOWN = 'unknown'
    LOCALHOST = 'localhost'
    MULTI_OPERATION = 'multi'
    PIPELINE_OPERATION = 'pipeline'
    HAS_REDIS_CLIENT = defined?(::Redis) &&
      Gem::Version.new(::Redis::VERSION) >= Gem::Version.new('5.0.0') &&
      !defined?(::RedisClient).nil?
  end
end
