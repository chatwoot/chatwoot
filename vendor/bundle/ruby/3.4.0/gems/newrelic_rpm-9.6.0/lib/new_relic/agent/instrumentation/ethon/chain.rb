# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Ethon
    module Chain
      def self.instrument!
        ::Ethon::Easy.class_eval do
          include NewRelic::Agent::Instrumentation::Ethon::Easy

          alias_method(:fabricate_without_tracing, :fabricate)
          def fabricate(url, action_name, options)
            fabricate_with_tracing(url, action_name, options) { fabricate_without_tracing(url, action_name, options) }
          end

          alias_method(:headers_equals_without_tracing, :headers=)
          def headers=(headers)
            headers_equals_with_tracing(headers) { headers_equals_without_tracing(headers) }
          end

          alias_method(:perform_without_tracing, :perform)
          def perform(*args)
            perform_with_tracing(*args) { perform_without_tracing(*args) }
          end
        end

        ::Ethon::Multi.class_eval do
          include NewRelic::Agent::Instrumentation::Ethon::Multi

          alias_method(:perform_without_tracing, :perform)
          def perform(*args)
            perform_with_tracing(*args) { perform_without_tracing(*args) }
          end
        end
      end
    end
  end
end
