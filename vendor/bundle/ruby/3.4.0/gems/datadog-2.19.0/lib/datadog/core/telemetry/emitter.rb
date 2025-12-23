# frozen_string_literal: true

require_relative 'request'
require_relative '../transport/response'
require_relative '../utils/sequence'
require_relative '../utils/forking'

module Datadog
  module Core
    module Telemetry
      # Class that emits telemetry events
      class Emitter
        attr_reader :transport, :logger

        extend Core::Utils::Forking

        # @param transport [Datadog::Core::Telemetry::Transport::Telemetry::Transport]
        #   Transport object that can be used to send telemetry requests
        def initialize(transport, logger: Datadog.logger, debug: false)
          @transport = transport
          @logger = logger
          @debug = !!debug
        end

        def debug?
          @debug
        end

        # Retrieves and emits a TelemetryRequest object based on the request type specified
        def request(event)
          seq_id = self.class.sequence.next
          payload = Request.build_payload(event, seq_id, debug: debug?)
          res = @transport.send_telemetry(request_type: event.type, payload: payload)
          logger.debug { "Telemetry sent for event `#{event.type}` (response code: #{res.code})" }
          res
        rescue => e
          logger.debug {
            "Unable to send telemetry request for event `#{begin
              event.type
            rescue
              "unknown"
            end}`: #{e}"
          }
          Core::Transport::InternalErrorResponse.new(e)
        end

        # Initializes a Sequence object to track seq_id if not already initialized; else returns stored
        # Sequence object
        def self.sequence
          after_fork! { @sequence = Datadog::Core::Utils::Sequence.new(1) }
          @sequence ||= Datadog::Core::Utils::Sequence.new(1)
        end
      end
    end
  end
end
