# frozen_string_literal: true

module Datadog
  module AppSec
    module SecurityEngine
      # A namespace for value-objects representing the result of WAF check.
      module Result
        # A generic result without indication of its type.
        class Base
          attr_reader :events, :actions, :derivatives, :duration_ns, :duration_ext_ns

          def initialize(events:, actions:, derivatives:, timeout:, duration_ns:, duration_ext_ns:)
            @events = events
            @actions = actions
            @derivatives = derivatives

            @timeout = timeout
            @duration_ns = duration_ns
            @duration_ext_ns = duration_ext_ns
          end

          def timeout?
            !!@timeout
          end

          def match?
            raise NotImplementedError
          end
        end

        # A result that indicates a security rule match
        class Match < Base
          def match?
            true
          end
        end

        # A result that indicates a successful security rules check without a match
        class Ok < Base
          def match?
            false
          end
        end

        # A result that indicates an internal security library error
        class Error
          attr_reader :events, :actions, :derivatives, :duration_ns, :duration_ext_ns

          def initialize(duration_ext_ns:)
            @events = []
            @actions = @derivatives = {}
            @duration_ns = 0
            @duration_ext_ns = duration_ext_ns
          end

          def timeout?
            false
          end

          def match?
            false
          end
        end
      end
    end
  end
end
