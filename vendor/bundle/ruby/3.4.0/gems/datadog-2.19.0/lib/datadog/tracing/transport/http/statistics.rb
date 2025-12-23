# frozen_string_literal: true

require_relative '../statistics'

module Datadog
  module Tracing
    module Transport
      module HTTP
        # Tracks statistics for HTTP transports
        module Statistics
          def self.included(base)
            base.include(Datadog::Tracing::Transport::Statistics)
            base.include(InstanceMethods)
          end

          # Instance methods for HTTP statistics
          module InstanceMethods
            # Decorate metrics for HTTP responses
            def metrics_for_response(response)
              super.tap do |metrics|
                # Add status code tag to api.responses metric
                if metrics.key?(:api_responses)
                  (metrics[:api_responses].options[:tags] ||= []).tap do |tags|
                    tags << metrics_tag_value(response.code)
                  end
                end
              end
            end

            private

            # The most common status code on a healthy tracer
            STATUS_CODE_200 = 'status_code:200'

            def metrics_tag_value(status_code)
              if status_code == 200
                STATUS_CODE_200 # DEV Saves string concatenation/creation for common case
              else
                "status_code:#{status_code}"
              end
            end
          end
        end
      end
    end
  end
end
