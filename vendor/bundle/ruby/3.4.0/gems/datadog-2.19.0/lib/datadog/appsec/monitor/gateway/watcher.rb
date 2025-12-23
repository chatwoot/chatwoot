# frozen_string_literal: true

require_relative '../../event'
require_relative '../../security_event'
require_relative '../../instrumentation/gateway'

module Datadog
  module AppSec
    module Monitor
      module Gateway
        # Watcher for Apssec internal events
        module Watcher
          ARBITRARY_VALUE = 'invalid'
          EVENT_LOGIN_SUCCESS = 'users.login.success'
          EVENT_LOGIN_FAILURE = 'users.login.failure'
          WATCHED_LOGIN_EVENTS = [EVENT_LOGIN_SUCCESS, EVENT_LOGIN_FAILURE].freeze

          class << self
            def watch
              gateway = Instrumentation.gateway

              watch_user_id(gateway)
              watch_user_login(gateway)
            end

            def watch_user_id(gateway = Instrumentation.gateway)
              gateway.watch('identity.set_user', :appsec) do |stack, user|
                context = AppSec.active_context

                if user.id.nil? && user.login.nil? && user.session_id.nil?
                  Datadog.logger.debug { 'AppSec: skipping WAF check because no user information was provided' }
                  next stack.call(user)
                end

                persistent_data = {}
                persistent_data['usr.id'] = user.id if user.id
                persistent_data['usr.login'] = user.login if user.login
                persistent_data['usr.session_id'] = user.session_id if user.session_id

                result = context.run_waf(persistent_data, {}, Datadog.configuration.appsec.waf_timeout)

                if result.match? || result.derivatives.any?
                  context.events.push(
                    AppSec::SecurityEvent.new(result, trace: context.trace, span: context.span)
                  )
                end

                if result.match?
                  AppSec::Event.tag_and_keep!(context, result)
                  AppSec::ActionsHandler.handle(result.actions)
                end

                stack.call(user)
              end
            end

            def watch_user_login(gateway = Instrumentation.gateway)
              gateway.watch('appsec.events.user_lifecycle', :appsec) do |stack, kind|
                context = AppSec.active_context

                next stack.call(kind) unless WATCHED_LOGIN_EVENTS.include?(kind)

                persistent_data = {"server.business_logic.#{kind}" => ARBITRARY_VALUE}
                result = context.run_waf(persistent_data, {}, Datadog.configuration.appsec.waf_timeout)

                if result.match? || result.derivatives.any?
                  context.events.push(
                    AppSec::SecurityEvent.new(result, trace: context.trace, span: context.span)
                  )
                end

                if result.match?
                  AppSec::Event.tag_and_keep!(context, result)
                  AppSec::ActionsHandler.handle(result.actions)
                end

                stack.call(kind)
              end
            end
          end
        end
      end
    end
  end
end
