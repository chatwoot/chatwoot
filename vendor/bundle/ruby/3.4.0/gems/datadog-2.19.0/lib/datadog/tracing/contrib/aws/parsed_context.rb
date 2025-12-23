# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Aws
        # A wrapper around Seahorse::Client::RequestContext
        class ParsedContext
          def initialize(context)
            @context = context
          end

          def safely(attr, fallback = nil)
            public_send(attr) rescue fallback
          end

          def resource
            "#{service}.#{operation}"
          end

          def operation
            context.operation_name
          end

          def params
            context.params
          end

          def http_response
            context.http_response
          end

          def status_code
            http_response.status_code
          end

          def http_method
            context.http_request.http_method
          end

          def region
            context.client.config.region
          end

          def retry_attempts
            context.retries
          end

          def path
            context.http_request.endpoint.path
          end

          def host
            context.http_request.endpoint.host
          end

          private

          attr_reader :context

          def service
            context.client.class.to_s.split('::')[1].downcase
          end
        end
      end
    end
  end
end
