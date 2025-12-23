# rubocop:disable Naming/FileName
# frozen_string_literal: true

require_relative '../../event'
require_relative '../../security_event'

module Datadog
  module AppSec
    module Contrib
      module Faraday
        # AppSec SSRF detection Middleware for Faraday
        class SSRFDetectionMiddleware < ::Faraday::Middleware
          def call(request_env)
            context = AppSec.active_context

            return @app.call(request_env) unless context && AppSec.rasp_enabled?

            ephemeral_data = {
              'server.io.net.url' => request_env.url.to_s
            }

            result = context.run_rasp(Ext::RASP_SSRF, {}, ephemeral_data, Datadog.configuration.appsec.waf_timeout)

            if result.match?
              AppSec::Event.tag_and_keep!(context, result)

              context.events.push(
                AppSec::SecurityEvent.new(result, trace: context.trace, span: context.span)
              )

              AppSec::ActionsHandler.handle(result.actions)
            end

            @app.call(request_env)
          end
        end
      end
    end
  end
end
# rubocop:enable Naming/FileName
