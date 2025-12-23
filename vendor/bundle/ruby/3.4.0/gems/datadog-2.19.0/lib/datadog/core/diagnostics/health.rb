# frozen_string_literal: true

require_relative '../metrics/client'
require_relative '../../tracing/diagnostics/health'

module Datadog
  module Core
    module Diagnostics
      # Health-related diagnostics
      module Health
        # Health metrics for diagnostics
        class Metrics < Core::Metrics::Client
          # TODO: Don't reference this. Have tracing add its metrics behavior.
          extend Tracing::Diagnostics::Health::Metrics
        end
      end
    end
  end
end
