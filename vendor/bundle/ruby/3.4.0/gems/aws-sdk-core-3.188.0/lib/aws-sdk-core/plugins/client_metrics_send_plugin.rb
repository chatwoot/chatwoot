# frozen_string_literal: true

require 'date'

module Aws
  module Plugins
    class ClientMetricsSendPlugin < Seahorse::Client::Plugin

      def add_handlers(handlers, config)
        if config.client_side_monitoring && config.client_side_monitoring_port
          # AttemptHandler comes just before we would retry an error.
          # Or before we would follow redirects.
          handlers.add(AttemptHandler, step: :sign, priority: 39)
          # LatencyHandler is as close to sending as possible.
          handlers.add(LatencyHandler, step: :sign, priority: 0)
        end
      end

      class LatencyHandler < Seahorse::Client::Handler
        def call(context)
          start_time = Aws::Util.monotonic_milliseconds
          resp = @handler.call(context)
          end_time = Aws::Util.monotonic_milliseconds
          latency = end_time - start_time
          context.metadata[:current_call_attempt].request_latency = latency
          resp
        end
      end

      class AttemptHandler < Seahorse::Client::Handler
        def call(context)
          request_metrics = context.metadata[:client_metrics]
          attempt_opts = {
            timestamp: DateTime.now.strftime('%Q').to_i,
            fqdn: context.http_request.endpoint.host,
            region: context.config.region,
            user_agent: context.http_request.headers["user-agent"],
          }
          # It will generally cause an error, but it is semantically valid for
          # credentials to not exist.
          if context.config.credentials
            attempt_opts[:access_key] =
              context.config.credentials.credentials.access_key_id
            attempt_opts[:session_token] =
              context.config.credentials.credentials.session_token
          end
          call_attempt = request_metrics.build_call_attempt(attempt_opts)
          context.metadata[:current_call_attempt] = call_attempt

          resp = @handler.call(context)
          if context.metadata[:redirect_region]
            call_attempt.region = context.metadata[:redirect_region]
          end
          headers = context.http_response.headers
          if headers.include?("x-amz-id-2")
            call_attempt.x_amz_id_2 = headers["x-amz-id-2"]
          end
          if headers.include?("x-amz-request-id")
            call_attempt.x_amz_request_id = headers["x-amz-request-id"]
          end
          if headers.include?("x-amzn-request-id")
            call_attempt.x_amzn_request_id = headers["x-amzn-request-id"]
          end
          call_attempt.http_status_code = context.http_response.status_code
          if e = resp.error
            e_name = _extract_error_name(e)
            e_msg = e.message
            call_attempt.aws_exception = "#{e_name}"
            call_attempt.aws_exception_msg = "#{e_msg}"
          end
          request_metrics.add_call_attempt(call_attempt)
          resp
        end

        private
        def _extract_error_name(error)
          if error.is_a?(Aws::Errors::ServiceError)
            error.class.code
          else
            error.class.name.to_s
          end
        end
      end
    end
  end
end
