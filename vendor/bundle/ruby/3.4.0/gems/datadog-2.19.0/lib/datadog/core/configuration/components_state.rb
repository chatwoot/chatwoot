# frozen_string_literal: true

module Datadog
  module Core
    module Configuration
      # Stores the state of component tree when replacing the tree.
      class ComponentsState
        def initialize(telemetry_enabled:, remote_started:)
          @telemetry_enabled = !!telemetry_enabled
          @remote_started = !!remote_started
        end

        def telemetry_enabled?
          @telemetry_enabled
        end

        def remote_started?
          @remote_started
        end
      end
    end
  end
end
