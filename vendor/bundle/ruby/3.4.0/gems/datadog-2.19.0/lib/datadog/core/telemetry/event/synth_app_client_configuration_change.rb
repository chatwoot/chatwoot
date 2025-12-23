# frozen_string_literal: true

require_relative 'base'

module Datadog
  module Core
    module Telemetry
      module Event
        # app-client-configuration-change event emitted instead of
        # app-started event for telemetry startups other than the initial
        # one in a process.
        #
        # dd-trace-rb generally creates a new component tree whenever
        # the tracer is reconfigured via Datadog.configure (with some
        # components potentially reused, if their configuration has not
        # changed). Telemetry system tests on the other hand expect there
        # to be one "tracer" per process, and do not permit multiple
        # app-started events to be emitted.
        #
        # To resolve this conflict, we replace second and onward app-started
        # events with app-client-configuration-change events.
        # To avoid diffing configuration, we send all parameters that are
        # sent in app-started event.
        #
        # It's a "quick fix" on top of a not-so-quick fix that omitted
        # second and subsequent app-started (and app-closing) events in the
        # first place, and only works with the existing hackery of app-started
        # and app-closing events.
        class SynthAppClientConfigurationChange < AppStarted
          def type
            'app-client-configuration-change'
          end

          def payload
            {
              configuration: configuration,
            }
          end
        end
      end
    end
  end
end
