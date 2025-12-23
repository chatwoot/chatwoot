# frozen_string_literal: true

require_relative 'base'

module Datadog
  module Core
    module Telemetry
      module Event
        # Telemetry class for the 'app-dependencies-loaded' event
        class AppDependenciesLoaded < Base
          def type
            'app-dependencies-loaded'
          end

          def payload
            {dependencies: dependencies}
          end

          private

          def dependencies
            Gem.loaded_specs.collect do |name, gem|
              {
                name: name,
                version: gem.version.to_s,
              }
            end
          end
        end
      end
    end
  end
end
