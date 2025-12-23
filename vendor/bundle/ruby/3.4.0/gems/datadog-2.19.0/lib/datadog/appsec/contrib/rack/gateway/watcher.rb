# frozen_string_literal: true

require_relative '../ext'
require_relative '../../../event'
require_relative '../../../security_event'
require_relative '../../../instrumentation/gateway'

module Datadog
  module AppSec
    module Contrib
      module Rack
        module Gateway
          # Watcher for Rack gateway events
          module Watcher
            class << self
              def watch
                gateway = Instrumentation.gateway

                watch_request(gateway)
                watch_response(gateway)
                watch_request_body(gateway)
                watch_request_finish(gateway)
              end

              def watch_request(gateway = Instrumentation.gateway)
                gateway.watch('rack.request', :appsec) do |stack, gateway_request|
                  context = gateway_request.env[AppSec::Ext::CONTEXT_KEY]

                  persistent_data = {
                    'server.request.cookies' => gateway_request.cookies,
                    'server.request.query' => gateway_request.query,
                    'server.request.uri.raw' => gateway_request.fullpath,
                    'server.request.headers' => gateway_request.headers,
                    'server.request.headers.no_cookies' => gateway_request.headers.dup.tap { |h| h.delete('cookie') },
                    'http.client_ip' => gateway_request.client_ip,
                    'server.request.method' => gateway_request.method
                  }

                  result = context.run_waf(persistent_data, {}, Datadog.configuration.appsec.waf_timeout)

                  if result.match? || !result.derivatives.empty?
                    context.events.push(
                      AppSec::SecurityEvent.new(result, trace: context.trace, span: context.span)
                    )
                  end

                  if result.match?
                    AppSec::Event.tag_and_keep!(context, result)
                    AppSec::ActionsHandler.handle(result.actions)
                  end

                  stack.call(gateway_request.request)
                end
              end

              def watch_response(gateway = Instrumentation.gateway)
                gateway.watch('rack.response', :appsec) do |stack, gateway_response|
                  context = gateway_response.context

                  persistent_data = {
                    'server.response.status' => gateway_response.status.to_s,
                    'server.response.headers' => gateway_response.headers,
                    'server.response.headers.no_cookies' => gateway_response.headers.dup.tap { |h| h.delete('set-cookie') }
                  }

                  result = context.run_waf(persistent_data, {}, Datadog.configuration.appsec.waf_timeout)

                  if result.match?
                    AppSec::Event.tag_and_keep!(context, result)

                    context.events.push(
                      AppSec::SecurityEvent.new(result, trace: context.trace, span: context.span)
                    )

                    AppSec::ActionsHandler.handle(result.actions)
                  end

                  stack.call(gateway_response.response)
                end
              end

              def watch_request_body(gateway = Instrumentation.gateway)
                gateway.watch('rack.request.body', :appsec) do |stack, gateway_request|
                  context = gateway_request.env[AppSec::Ext::CONTEXT_KEY]

                  persistent_data = {
                    'server.request.body' => gateway_request.form_hash
                  }

                  result = context.run_waf(persistent_data, {}, Datadog.configuration.appsec.waf_timeout)

                  if result.match?
                    AppSec::Event.tag_and_keep!(context, result)

                    context.events.push(
                      AppSec::SecurityEvent.new(result, trace: context.trace, span: context.span)
                    )

                    AppSec::ActionsHandler.handle(result.actions)
                  end

                  stack.call(gateway_request.request)
                end
              end

              # NOTE: In the current state we unable to substibe twice to the same
              #       event within the same group. Ideally this code should live
              #       somewhere closer to identity related monitor.
              # WARNING: The Gateway is a subject of refactoring
              def watch_request_finish(gateway = Instrumentation.gateway)
                gateway.watch('rack.request.finish', :appsec) do |stack, gateway_request|
                  context = gateway_request.env[AppSec::Ext::CONTEXT_KEY]

                  if context.span.nil? || !gateway.pushed?('appsec.events.user_lifecycle')
                    next stack.call(gateway_request.request)
                  end

                  gateway_request.headers.each do |name, value|
                    if !Ext::COLLECTABLE_REQUEST_HEADERS.include?(name) &&
                        !Ext::IDENTITY_COLLECTABLE_REQUEST_HEADERS.include?(name)
                      next
                    end

                    context.span["http.request.headers.#{name}"] ||= value
                  end

                  stack.call(gateway_request.request)
                end
              end
            end
          end
        end
      end
    end
  end
end
