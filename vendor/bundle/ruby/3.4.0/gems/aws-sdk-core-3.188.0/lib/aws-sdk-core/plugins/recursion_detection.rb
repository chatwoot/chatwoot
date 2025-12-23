# frozen_string_literal: true

module Aws
  module Plugins
    # @api private
    class RecursionDetection < Seahorse::Client::Plugin

      # @api private
      class Handler < Seahorse::Client::Handler
        def call(context)

          unless context.http_request.headers.key?('x-amzn-trace-id')
            if ENV['AWS_LAMBDA_FUNCTION_NAME'] &&
              (trace_id = validate_header(ENV['_X_AMZN_TRACE_ID']))
              context.http_request.headers['x-amzn-trace-id'] = trace_id
            end
          end
          @handler.call(context)
        end

        private
        def validate_header(header_value)
          return unless header_value

          if (header_value.chars & (0..31).map(&:chr)).any?
            raise ArgumentError, 'Invalid _X_AMZN_TRACE_ID value: '\
              'contains ASCII control characters'
          end
          header_value
        end
      end

      # should be at the end of build so that
      # modeled traits / service customizations apply first
      handler(Handler, step: :build, order: 99)
    end
  end
end
