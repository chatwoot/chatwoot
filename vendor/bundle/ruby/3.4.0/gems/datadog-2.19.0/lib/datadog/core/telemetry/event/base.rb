# frozen_string_literal: true

module Datadog
  module Core
    module Telemetry
      module Event
        # Base class for all Telemetry V2 events.
        class Base
          # The type of the event.
          # It must be one of the stings defined in the Telemetry V2
          # specification for event names.
          def type
            raise NotImplementedError, 'Must be implemented by subclass'
          end

          # The JSON payload for the event.
          def payload
            {}
          end

          # Override equality to allow for deduplication
          # The basic implementation is to check if the other object is an instance of the same class.
          # This works for events that have no attributes.
          # For events with attributes, you should override this method to compare the attributes.
          def ==(other)
            other.is_a?(self.class)
          end

          # @see #==
          alias_method :eql?, :==

          # @see #==
          def hash
            self.class.hash
          end
        end
      end
    end
  end
end
