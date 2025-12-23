# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    class DatabaseAdapter
      VERSIONS = {
        '6.1.0' => proc { ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] },
        '4.0.0' => proc { ActiveRecord::Base.connection_config[:adapter] },
        '3.0.0' => proc { |env| ActiveRecord::Base.configurations[env]['adapter'] }
      }

      def self.value
        return unless defined? ActiveRecord::Base

        new(::NewRelic::Control.instance.env, ActiveRecord::VERSION::STRING).value
      end

      attr_reader :env, :version

      def initialize(env, version)
        @env = env
        @version = Gem::Version.new(version)
      end

      def value
        match = VERSIONS.keys.find { |key| version >= Gem::Version.new(key) }
        return unless match

        VERSIONS[match].call(env)
      end
    end
  end
end
