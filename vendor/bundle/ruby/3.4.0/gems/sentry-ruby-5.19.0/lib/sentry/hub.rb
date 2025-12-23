# frozen_string_literal: true

require "sentry/scope"
require "sentry/client"
require "sentry/session"

module Sentry
  class Hub
    include ArgumentCheckingHelper

    attr_reader :last_event_id

    def initialize(client, scope)
      first_layer = Layer.new(client, scope)
      @stack = [first_layer]
      @last_event_id = nil
    end

    def new_from_top
      Hub.new(current_client, current_scope)
    end

    def current_client
      current_layer&.client
    end

    def configuration
      current_client.configuration
    end

    def current_scope
      current_layer&.scope
    end

    def clone
      layer = current_layer

      if layer
        scope = layer.scope&.dup

        Hub.new(layer.client, scope)
      end
    end

    def bind_client(client)
      layer = current_layer

      if layer
        layer.client = client
      end
    end

    def configure_scope(&block)
      block.call(current_scope)
    end

    def with_scope(&block)
      push_scope
      yield(current_scope)
    ensure
      pop_scope
    end

    def push_scope
      new_scope =
        if current_scope
          current_scope.dup
        else
          Scope.new
        end

      @stack << Layer.new(current_client, new_scope)
    end

    def pop_scope
      @stack.pop
    end

    def start_transaction(transaction: nil, custom_sampling_context: {}, instrumenter: :sentry, **options)
      return unless configuration.tracing_enabled?
      return unless instrumenter == configuration.instrumenter

      transaction ||= Transaction.new(**options.merge(hub: self))

      sampling_context = {
        transaction_context: transaction.to_hash,
        parent_sampled: transaction.parent_sampled
      }

      sampling_context.merge!(custom_sampling_context)
      transaction.set_initial_sample_decision(sampling_context: sampling_context)

      transaction.start_profiler!

      transaction
    end

    def with_child_span(instrumenter: :sentry, **attributes, &block)
      return yield(nil) unless instrumenter == configuration.instrumenter

      current_span = current_scope.get_span
      return yield(nil) unless current_span

      result = nil

      begin
        current_span.with_child_span(**attributes) do |child_span|
          current_scope.set_span(child_span)
          result = yield(child_span)
        end
      ensure
        current_scope.set_span(current_span)
      end

      result
    end

    def capture_exception(exception, **options, &block)
      if RUBY_PLATFORM == "java"
        check_argument_type!(exception, ::Exception, ::Java::JavaLang::Throwable)
      else
        check_argument_type!(exception, ::Exception)
      end

      return if Sentry.exception_captured?(exception)

      return unless current_client

      options[:hint] ||= {}
      options[:hint][:exception] = exception

      event = current_client.event_from_exception(exception, options[:hint])

      return unless event

      current_scope.session&.update_from_exception(event.exception)

      capture_event(event, **options, &block).tap do
        # mark the exception as captured so we can use this information to avoid duplicated capturing
        exception.instance_variable_set(Sentry::CAPTURED_SIGNATURE, true)
      end
    end

    def capture_message(message, **options, &block)
      check_argument_type!(message, ::String)

      return unless current_client

      options[:hint] ||= {}
      options[:hint][:message] = message
      backtrace = options.delete(:backtrace)
      event = current_client.event_from_message(message, options[:hint], backtrace: backtrace)

      return unless event

      capture_event(event, **options, &block)
    end

    def capture_check_in(slug, status, **options)
      check_argument_type!(slug, ::String)
      check_argument_includes!(status, Sentry::CheckInEvent::VALID_STATUSES)

      return unless current_client

      options[:hint] ||= {}
      options[:hint][:slug] = slug

      event = current_client.event_from_check_in(
        slug,
        status,
        options[:hint],
        duration: options.delete(:duration),
        monitor_config: options.delete(:monitor_config),
        check_in_id: options.delete(:check_in_id)
      )

      return unless event

      capture_event(event, **options)
      event.check_in_id
    end

    def capture_event(event, **options, &block)
      check_argument_type!(event, Sentry::Event)

      return unless current_client

      hint = options.delete(:hint) || {}
      scope = current_scope.dup

      if block
        block.call(scope)
      elsif custom_scope = options[:scope]
        scope.update_from_scope(custom_scope)
      elsif !options.empty?
        unsupported_option_keys = scope.update_from_options(**options)

        unless unsupported_option_keys.empty?
          configuration.log_debug <<~MSG
            Options #{unsupported_option_keys} are not supported and will not be applied to the event.
            You may want to set them under the `extra` option.
          MSG
        end
      end

      event = current_client.capture_event(event, scope, hint)

      if event && configuration.debug
        configuration.log_debug(event.to_json_compatible)
      end

      @last_event_id = event&.event_id if event.is_a?(Sentry::ErrorEvent)
      event
    end

    def add_breadcrumb(breadcrumb, hint: {})
      return unless configuration.enabled_in_current_env?

      if before_breadcrumb = current_client.configuration.before_breadcrumb
        breadcrumb = before_breadcrumb.call(breadcrumb, hint)
      end

      return unless breadcrumb

      current_scope.add_breadcrumb(breadcrumb)
    end

    # this doesn't do anything to the already initialized background worker
    # but it temporarily disables dispatching events to it
    def with_background_worker_disabled(&block)
      original_background_worker_threads = configuration.background_worker_threads
      configuration.background_worker_threads = 0

      block.call
    ensure
      configuration.background_worker_threads = original_background_worker_threads
    end

    def start_session
      return unless current_scope
      current_scope.set_session(Session.new)
    end

    def end_session
      return unless current_scope
      session = current_scope.session
      current_scope.set_session(nil)

      return unless session
      session.close
      Sentry.session_flusher.add_session(session)
    end

    def with_session_tracking(&block)
      return yield unless configuration.session_tracking?

      start_session
      yield
    ensure
      end_session
    end

    def get_traceparent
      return nil unless current_scope

      current_scope.get_span&.to_sentry_trace ||
        current_scope.propagation_context.get_traceparent
    end

    def get_baggage
      return nil unless current_scope

      current_scope.get_span&.to_baggage ||
        current_scope.propagation_context.get_baggage&.serialize
    end

    def get_trace_propagation_headers
      headers = {}

      traceparent = get_traceparent
      headers[SENTRY_TRACE_HEADER_NAME] = traceparent if traceparent

      baggage = get_baggage
      headers[BAGGAGE_HEADER_NAME] = baggage if baggage && !baggage.empty?

      headers
    end

    def get_trace_propagation_meta
      get_trace_propagation_headers.map do |k, v|
        "<meta name=\"#{k}\" content=\"#{v}\">"
      end.join("\n")
    end

    def continue_trace(env, **options)
      configure_scope { |s| s.generate_propagation_context(env) }

      return nil unless configuration.tracing_enabled?

      propagation_context = current_scope.propagation_context
      return nil unless propagation_context.incoming_trace

      Transaction.new(
        hub: self,
        trace_id: propagation_context.trace_id,
        parent_span_id: propagation_context.parent_span_id,
        parent_sampled: propagation_context.parent_sampled,
        baggage: propagation_context.baggage,
        **options
      )
    end

    private

    def current_layer
      @stack.last
    end

    class Layer
      attr_accessor :client
      attr_reader :scope

      def initialize(client, scope)
        @client = client
        @scope = scope
      end
    end
  end
end
