# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Instrumentation
      module GRPC
        module Client
          class RequestWrapper
            attr_reader :newrelic_metadata

            def initialize(host)
              @host = host
              @newrelic_metadata = {}
            end

            def host_from_header
              @host
            end

            def []=(key, value)
              @newrelic_metadata[key] = value
            end
          end
        end
      end
    end
  end
end
