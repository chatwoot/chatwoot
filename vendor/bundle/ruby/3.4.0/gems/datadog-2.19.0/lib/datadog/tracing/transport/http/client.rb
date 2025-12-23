# frozen_string_literal: true

require_relative 'statistics'
require_relative '../../../core/transport/http/env'
require_relative '../../../core/transport/http/response'

module Datadog
  module Tracing
    module Transport
      module HTTP
        # Routes, encodes, and sends tracer data to the trace agent via HTTP.
        class Client
          include Datadog::Tracing::Transport::HTTP::Statistics

          attr_reader :api, :logger

          def initialize(api, logger: Datadog.logger)
            @api = api
            @logger = logger
          end

          def send_request(request, &block)
            # Build request into env
            env = build_env(request)

            # Get responses from API
            response = yield(api, env)

            # Update statistics
            update_stats_from_response!(response)

            response
          rescue StandardError => e
            message =
              "Internal error during #{self.class.name} request. Cause: #{e.class.name} #{e.message} " \
                "Location: #{Array(e.backtrace).first}"

            # Log error
            if stats.consecutive_errors > 0
              logger.debug(message)
            else
              # Not to report telemetry logs
              logger.error(message)
            end

            # Update statistics
            update_stats_from_exception!(e)

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
