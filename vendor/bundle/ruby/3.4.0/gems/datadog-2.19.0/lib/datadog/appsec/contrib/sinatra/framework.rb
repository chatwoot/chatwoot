# frozen_string_literal: true

module Datadog
  module AppSec
    module Contrib
      # Instrument Sinatra.
      module Sinatra
        # Sinatra framework code, used to essentially:
        # - handle configuration entries which are specific to Datadog tracing
        # - instrument parts of the framework when needed
        module Framework
          # Configure Rack from Sinatra, but only if Rack has not been configured manually beforehand
          def self.setup
            Datadog.configuration.appsec.instrument(:rack)
          end
        end
      end
    end
  end
end
