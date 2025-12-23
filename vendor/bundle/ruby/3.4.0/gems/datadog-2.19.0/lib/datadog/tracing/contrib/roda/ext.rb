# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Roda
        # Roda integration constants
        module Ext
          APP = 'roda'
          ENV_ENABLED = 'DD_TRACE_RODA_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_RODA_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_RODA_ANALYTICS_SAMPLE_RATE'
          SPAN_REQUEST = 'roda.request'
        end
      end
    end
  end
end
