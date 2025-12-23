# frozen_string_literal: true

require_relative 'api_security/sampler'

module Datadog
  module AppSec
    # A namespace for API Security features.
    module APISecurity
      def self.enabled?
        Datadog.configuration.appsec.api_security.enabled?
      end

      def self.sample?(request, response)
        Sampler.thread_local.sample?(request, response)
      end

      def self.sample_trace?(trace)
        # NOTE: Reads as "if trace is priority sampled or if in standalone mode"
        trace&.priority_sampled? || !Datadog.configuration.apm.tracing.enabled
      end
    end
  end
end
