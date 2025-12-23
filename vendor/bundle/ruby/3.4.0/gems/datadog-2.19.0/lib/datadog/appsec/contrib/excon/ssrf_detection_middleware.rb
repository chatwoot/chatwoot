# rubocop:disable Naming/FileName
# frozen_string_literal: true

require 'excon'

require_relative '../../event'
require_relative '../../security_event'

module Datadog
  module AppSec
    module Contrib
      module Excon
        # AppSec Middleware for Excon
        class SSRFDetectionMiddleware < ::Excon::Middleware::Base
          def request_call(data)
            return super unless AppSec.rasp_enabled? && AppSec.active_context

            context = AppSec.active_context

            request_url = URI.join("#{data[:scheme]}://#{data[:host]}", data[:path]).to_s
            ephemeral_data = {'server.io.net.url' => request_url}

            result = context.run_rasp(Ext::RASP_SSRF, {}, ephemeral_data, Datadog.configuration.appsec.waf_timeout)

            if result.match?
              AppSec::Event.tag_and_keep!(context, result)

              context.events.push(
                AppSec::SecurityEvent.new(result, trace: context.trace, span: context.span)
              )

              AppSec::ActionsHandler.handle(result.actions)
            end

            super
          end
        end
      end
    end
  end
end
# rubocop:enable Naming/FileName
