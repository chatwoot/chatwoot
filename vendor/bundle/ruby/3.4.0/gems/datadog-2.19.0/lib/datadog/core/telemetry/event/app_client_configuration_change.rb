# frozen_string_literal: true

require_relative 'base'

module Datadog
  module Core
    module Telemetry
      module Event
        # Telemetry class for the 'app-client-configuration-change' event
        class AppClientConfigurationChange < Base
          attr_reader :changes, :origin

          def type
            'app-client-configuration-change'
          end

          def initialize(changes, origin)
            super()
            @changes = changes
            @origin = origin
          end

          def payload
            {configuration: configuration}
          end

          def configuration
            config = Datadog.configuration
            seq_id = Event.configuration_sequence.next

            res = @changes.map do |name, value|
              {
                name: name,
                value: value,
                origin: @origin,
                seq_id: seq_id,
              }
            end

            # DEV: This seems unnecessary (we send the state of sca_enabled for each remote config change)
            unless config.dig('appsec', 'sca_enabled').nil?
              res << {
                name: 'appsec.sca_enabled',
                value: config.appsec.sca_enabled,
                origin: 'code',
                seq_id: seq_id,
              }
            end

            res
          end

          def ==(other)
            other.is_a?(AppClientConfigurationChange) && other.changes == @changes && other.origin == @origin
          end

          alias_method :eql?, :==

          def hash
            [self.class, @changes, @origin].hash
          end
        end
      end
    end
  end
end
