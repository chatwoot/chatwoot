# frozen_string_literal: true

require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module Redis
        # Description of Redis integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('3.2')

          # Support `Config#custom`
          # https://github.com/redis-rb/redis-client/blob/master/CHANGELOG.md#0110
          REDISCLIENT_MINIMUM_VERSION = Gem::Version.new('0.11.0')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :redis, auto_patch: true

          # Until Redis 4, all instrumentation happened in one gem: redis.
          # Since Redis 5, instrumentation happens in a separate gem: redis-client.
          # Because Redis 4 does not depend on redis-client, it's possible for both gems to be installed at the same time.
          # For example, if Sidekiq 7 and Redis 4 are installed: both redis and redis-client will be installed.
          # If redis-client and redis > 5 are installed, than they will be in sync, and only redis-client will be installed.
          def self.version
            redis_version || redis_client_version
          end

          def self.redis_version
            Gem.loaded_specs['redis'] && Gem.loaded_specs['redis'].version
          end

          def self.redis_client_version
            Gem.loaded_specs['redis-client'] && Gem.loaded_specs['redis-client'].version
          end

          def self.loaded?
            redis_loaded? || redis_client_loaded?
          end

          def self.redis_loaded?
            !defined?(::Redis).nil?
          end

          def self.redis_client_loaded?
            !defined?(::RedisClient).nil?
          end

          def self.compatible?
            super && (redis_compatible? || redis_client_compatible?)
          end

          def self.redis_compatible?
            !!(redis_version && redis_version >= MINIMUM_VERSION)
          end

          def self.redis_client_compatible?
            !!(redis_client_version && redis_client_version >= REDISCLIENT_MINIMUM_VERSION)
          end

          def new_configuration
            Configuration::Settings.new
          end

          def patcher
            Patcher
          end

          def resolver
            @resolver ||= Configuration::Resolver.new
          end
        end
      end
    end
  end
end
