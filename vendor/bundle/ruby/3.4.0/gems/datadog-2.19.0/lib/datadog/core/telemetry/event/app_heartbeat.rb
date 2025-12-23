# frozen_string_literal: true

require_relative 'base'

module Datadog
  module Core
    module Telemetry
      module Event
        # Telemetry class for the 'app-heartbeat' event
        class AppHeartbeat < Base
          def type
            'app-heartbeat'
          end
        end
      end
    end
  end
end
