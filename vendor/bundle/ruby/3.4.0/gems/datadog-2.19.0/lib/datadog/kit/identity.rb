# frozen_string_literal: true

require_relative '../appsec/instrumentation/gateway/argument'

module Datadog
  module Kit
    # Tracking identity via traces
    module Identity
      class << self
        # Attach user information to the trace
        #
        # @param trace [TraceOperation] Trace to attach data to. Defaults to
        #   active trace.
        # @param span [SpanOperation] Span to attach data to. Defaults to
        #   active span on trace. Note that this should be a service entry span.
        #   When AppSec is enabled, the expected span and trace are automatically
        #   used as defaults.
        # @param id [String] Mandatory. Username or client id extracted
        #   from the access token or Authorization header in the inbound request
        #   from outside the system.
        # @param email [String] Email of the authenticated user associated
        #   to the trace.
        # @param name [String] User-friendly name. To be displayed in the
        #   UI if set.
        # @param session_id [String] Session ID of the authenticated user.
        # @param role [String] Actual/assumed role the client is making
        #   the request under extracted from token or application security
        #   context.
        # @param scope [String] Scopes or granted authorities the client
        #   currently possesses extracted from token or application security
        #   context. The value would come from the scope associated with an OAuth
        #   2.0 Access Token or an attribute value in a SAML 2.0 Assertion.
        # @param others [Hash<Symbol, String>] Additional free-form
        #   user information to attach to the trace.
        #
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        def set_user(
          trace = nil, span = nil, id:, email: nil, name: nil, session_id: nil, role: nil, scope: nil, **others
        )
          raise ArgumentError, 'missing required key: :id' if id.nil?

          # enforce types

          raise TypeError, ':id must be a String'         unless id.is_a?(String)
          raise TypeError, ':email must be a String'      unless email.nil? || email.is_a?(String)
          raise TypeError, ':name must be a String'       unless name.nil? || name.is_a?(String)
          raise TypeError, ':session_id must be a String' unless session_id.nil? || session_id.is_a?(String)
          raise TypeError, ':role must be a String'       unless role.nil? || role.is_a?(String)
          raise TypeError, ':scope must be a String'      unless scope.nil? || scope.is_a?(String)

          others.each do |k, v|
            raise TypeError, "#{k.inspect} must be a String" unless v.nil? || v.is_a?(String)
          end

          set_trace_and_span_context('set_user', trace, span) do |_active_trace, active_span|
            # set tags once data is known consistent
            active_span.set_tag('usr.id', id)
            active_span.set_tag('usr.email', email)           unless email.nil?
            active_span.set_tag('usr.name', name)             unless name.nil?
            active_span.set_tag('usr.session_id', session_id) unless session_id.nil?
            active_span.set_tag('usr.role', role)             unless role.nil?
            active_span.set_tag('usr.scope', scope)           unless scope.nil?

            others.each do |k, v|
              active_span.set_tag("usr.#{k}", v) unless v.nil?
            end

            if Datadog::AppSec.active_context
              active_span.set_tag('_dd.appsec.user.collection_mode', 'sdk')

              user = ::Datadog::AppSec::Instrumentation::Gateway::User.new(id, others[:login], session_id)
              ::Datadog::AppSec::Instrumentation.gateway.push('identity.set_user', user)
            end
          end
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/PerceivedComplexity
        # rubocop:enable Metrics/CyclomaticComplexity

        private

        def set_trace_and_span_context(method, trace = nil, span = nil)
          if (appsec_context = Datadog::AppSec.active_context)
            trace = appsec_context.trace
            span = appsec_context.span
          end

          trace ||= Datadog::Tracing.active_trace
          span ||= trace && trace.active_span || Datadog::Tracing.active_span

          unless trace && span
            Datadog.logger.debug(
              "Tracing not enabled. Method ##{method} is a no-op. Please enable tracing if you want ##{method}"\
              ' to track this events'
            )
            return
          end

          raise ArgumentError, "span #{span.id} does not belong to trace #{trace.id}" if trace.id != span.trace_id

          yield(trace, span)
        end
      end
    end
  end
end
