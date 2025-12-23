# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Datastores
      module Mongo
        def self.is_supported_version?
          defined?(::Mongo) && is_monitoring_enabled?
        end

        def self.is_unsupported_2x?
          defined?(::Mongo::VERSION) &&
            Gem::Version.new(::Mongo::VERSION).segments[0] == 2 &&
            !self.is_monitoring_enabled?
        end

        def self.is_monitoring_enabled?
          defined?(::Mongo::Monitoring) # @since 2.1.0
        end
      end
    end
  end
end
