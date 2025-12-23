# frozen_string_literal: true

require_relative '../../identity'

module Datadog
  module Kit
    module AppSec
      module Events
        # The second version of Business Logic Events SDK
        module V2
          LOGIN_SUCCESS_EVENT = 'users.login.success'
          LOGIN_FAILURE_EVENT = 'users.login.failure'
          TELEMETRY_METRICS_NAMESPACE = 'appsec'
          TELEMETRY_METRICS_SDK_EVENT = 'sdk.event'
          TELEMETRY_METRICS_SDK_VERSION = 'v2'
          TELEMETRY_METRICS_EVENTS_INTO_TYPES = {
            LOGIN_SUCCESS_EVENT => 'login_success',
            LOGIN_FAILURE_EVENT => 'login_failure'
          }.freeze

          class << self
            # Attach user login success information to the service entry span
            # and trigger AppSec event processing.
            #
            # @param login [String] The user login (e.g., username or email).
            # @param user_or_id [String, Hash<Symbol, String>] (optional) If a
            #   String, considered as a user ID, if a Hash, considered as a user
            #   attributes. The Hash must include `:id` as a key.
            # @param metadata [Hash<Symbol, String>] Additional flat free-form
            #   metadata to attach to the event.
            #
            # @example Login only
            #   Datadog::Kit::AppSec::Events::V2.track_user_login_success('alice@example.com')
            #
            # @example Login and user attributes
            #   Datadog::Kit::AppSec::Events::V2.track_user_login_success(
            #     'alice@example.com',
            #     { id: 'user-123', email: 'alice@example.com', name: 'Alice' },
            #     ip: '192.168.1.1', device: 'mobile', 'usr.country': 'US'
            #   )
            #
            # @return [void]
            def track_user_login_success(login, user_or_id = nil, metadata = {})
              trace = service_entry_trace
              span = service_entry_span

              if trace.nil? || span.nil?
                return Datadog.logger.warn(
                  'Kit::AppSec: Tracing is not enabled. Please enable tracing if you want to track events'
                )
              end

              raise TypeError, '`login` argument must be a String' unless login.is_a?(String)
              raise TypeError, '`metadata` argument must be a Hash' unless metadata.is_a?(Hash)

              user_attributes = build_user_attributes(user_or_id, login)

              set_span_tags(span, metadata, namespace: LOGIN_SUCCESS_EVENT)
              set_span_tags(span, user_attributes, namespace: "#{LOGIN_SUCCESS_EVENT}.usr")
              span.set_tag('appsec.events.users.login.success.track', 'true')
              span.set_tag('_dd.appsec.events.users.login.success.sdk', 'true')

              trace.keep!

              record_event_telemetry_metric(LOGIN_SUCCESS_EVENT)
              ::Datadog::AppSec::Instrumentation.gateway.push('appsec.events.user_lifecycle', LOGIN_SUCCESS_EVENT)

              # NOTE: Guard-clause will not work with Steep typechecking
              return Kit::Identity.set_user(trace, span, **user_attributes) if user_attributes.key?(:id) # steep:ignore

              # NOTE: This is a fallback for the case when we don't have an ID,
              #       but need to trigger WAF.
              user = ::Datadog::AppSec::Instrumentation::Gateway::User.new(nil, login)
              ::Datadog::AppSec::Instrumentation.gateway.push('identity.set_user', user)
            end

            # Attach user login failure information to the service entry span
            # and trigger AppSec event processing.
            #
            # @param login [String] The user login (e.g., username or email).
            # @param user_exists [Boolean] Whether the user exists in the system.
            # @param metadata [Hash<Symbol, String>] Additional flat free-form
            #   metadata to attach to the event.
            #
            # @example Login only
            #   Datadog::Kit::AppSec::Events::V2.track_user_login_failure('alice@example.com')
            #
            # @example With user existence and metadata
            #   Datadog::Kit::AppSec::Events::V2.track_user_login_failure(
            #     'alice@example.com',
            #     true,
            #     ip: '192.168.1.1', device: 'mobile', 'usr.country': 'US'
            #   )
            #
            # @return [void]
            def track_user_login_failure(login, user_exists = false, metadata = {})
              trace = service_entry_trace
              span = service_entry_span

              if trace.nil? || span.nil?
                return Datadog.logger.warn(
                  'Kit::AppSec: Tracing is not enabled. Please enable tracing if you want to track events'
                )
              end

              raise TypeError, '`login` argument must be a String' unless login.is_a?(String)
              raise TypeError, '`metadata` argument must be a Hash' unless metadata.is_a?(Hash)

              unless user_exists.is_a?(TrueClass) || user_exists.is_a?(FalseClass)
                raise TypeError, '`user_exists` argument must be a boolean'
              end

              set_span_tags(span, metadata, namespace: LOGIN_FAILURE_EVENT)
              span.set_tag('appsec.events.users.login.failure.track', 'true')
              span.set_tag('_dd.appsec.events.users.login.failure.sdk', 'true')
              span.set_tag('appsec.events.users.login.failure.usr.login', login)
              span.set_tag('appsec.events.users.login.failure.usr.exists', user_exists.to_s)

              trace.keep!

              record_event_telemetry_metric(LOGIN_FAILURE_EVENT)
              ::Datadog::AppSec::Instrumentation.gateway.push('appsec.events.user_lifecycle', LOGIN_FAILURE_EVENT)

              user = ::Datadog::AppSec::Instrumentation::Gateway::User.new(nil, login)
              ::Datadog::AppSec::Instrumentation.gateway.push('identity.set_user', user)
            end

            private

            # NOTE: Current tracer implementation does not provide a way to
            #       get the service entry span. This is a shortcut we take now.
            def service_entry_trace
              return Datadog::Tracing.active_trace unless Datadog::AppSec.active_context

              Datadog::AppSec.active_context&.trace
            end

            # NOTE: Current tracer implementation does not provide a way to
            #       get the service entry span. This is a shortcut we take now.
            def service_entry_span
              return Datadog::Tracing.active_span unless Datadog::AppSec.active_context

              Datadog::AppSec.active_context&.span
            end

            def build_user_attributes(user_or_id, login)
              raise TypeError, '`login` argument must be a String' unless login.is_a?(String)

              case user_or_id
              when nil
                { login: login }
              when String
                { login: login, id: user_or_id }
              when Hash
                raise ArgumentError, 'missing required user key `:id`' unless user_or_id.key?(:id)
                raise TypeError, 'user key `:id` must be a String' unless user_or_id[:id].is_a?(String)

                user_or_id.merge(login: login)
              else
                raise TypeError, '`user_or_id` argument must be either String or Hash'
              end
            end

            def set_span_tags(span, tags, namespace:)
              tags.each do |name, value|
                next if value.nil?

                span.set_tag("appsec.events.#{namespace}.#{name}", value)
              end
            end

            # TODO: In case if we need to introduce telemetry metrics to the SDK v1
            #       or highly increase the number of metrics, this method should be
            #       extracted into a proper module.
            def record_event_telemetry_metric(event)
              telemetry = ::Datadog.send(:components, allow_initialization: false)&.telemetry

              if telemetry.nil?
                return Datadog.logger.debug(
                  'Kit::AppSec: Telemetry component is unavailable. Skip recording SDK metrics'
                )
              end

              tags = {
                event_type: TELEMETRY_METRICS_EVENTS_INTO_TYPES[event],
                sdk_version: TELEMETRY_METRICS_SDK_VERSION
              }
              telemetry.inc(TELEMETRY_METRICS_NAMESPACE, TELEMETRY_METRICS_SDK_EVENT, 1, tags: tags)
            end
          end
        end
      end
    end
  end
end
