# frozen_string_literal: true

require_relative '../../../transport/http/env'
require_relative '../../../transport/http/response'

# TODO: Decouple transport/http/client
#
# The standard one does `include Transport::HTTP::Statistics` and performs
# stats updates, which may or may not be desirable in general.

module Datadog
  module Core
    module Telemetry
      module Transport
        module HTTP
          # Routes, encodes, and sends DI data to the trace agent via HTTP.
          class Client
            attr_reader :api, :logger

            def initialize(api, logger:)
              @api = api
              @logger = logger
            end

            def send_request(request, &block)
              # Build request into env
              env = build_env(request)

              # Get responses from API
              yield(api, env)
            rescue => e
              message =
                "Internal error during #{self.class.name} request. Cause: #{e.class.name} #{e.message} " \
                  "Location: #{Array(e.backtrace).first}"

              logger.debug(message)

              Datadog::Core::Transport::InternalErrorResponse.new(e)
            end

            def build_env(request)
              Datadog::Core::Transport::HTTP::Env.new(request)
            end
          end
        end
      end
    end
  end
end
