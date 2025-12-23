# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  # The Trace API allows recording a set of events, triggered as a result of a
  # single logical operation, consolidated across various components of an
  # application.
  module Trace
    extend self

    CURRENT_SPAN_KEY = Context.create_key('current-span')

    private_constant :CURRENT_SPAN_KEY

    # An invalid trace identifier, a 16-byte string with all zero bytes.
    INVALID_TRACE_ID = ("\0" * 16).b

    # An invalid span identifier, an 8-byte string with all zero bytes.
    INVALID_SPAN_ID = ("\0" * 8).b

    # Generates a valid trace identifier, a 16-byte string with at least one
    # non-zero byte.
    #
    # @return [String] a valid trace ID.
    def generate_trace_id
      id = Random.bytes(16)
      id = Random.bytes(16) while id == INVALID_TRACE_ID
      id
    end

    # Generates a valid span identifier, an 8-byte string with at least one
    # non-zero byte.
    #
    # @return [String] a valid span ID.
    def generate_span_id
      id = Random.bytes(8)
      id = Random.bytes(8) while id == INVALID_SPAN_ID
      id
    end

    # Returns the current span from the current or provided context
    #
    # @param [optional Context] context The context to lookup the current
    #   {Span} from. Defaults to Context.current
    def current_span(context = nil)
      context ||= Context.current
      context.value(CURRENT_SPAN_KEY) || Span::INVALID
    end

    # Returns a context containing the span, derived from the optional parent
    # context, or the current context if one was not provided.
    #
    # @param [optional Context] context The context to use as the parent for
    #   the returned context
    def context_with_span(span, parent_context: Context.current)
      parent_context.set_value(CURRENT_SPAN_KEY, span)
    end

    # Activates/deactivates the Span within the current Context, which makes the "current span"
    # available implicitly.
    #
    # On exit, the Span that was active before calling this method will be reactivated.
    #
    # @param [Span] span the span to activate
    # @yield [span, context] yields span and a context containing the span to the block.
    def with_span(span)
      Context.with_value(CURRENT_SPAN_KEY, span) { |c, s| yield s, c }
    end

    # Wraps a SpanContext with an object implementing the Span interface. This is done in order
    # to expose a SpanContext as a Span in operations such as in-process Span propagation.
    #
    # @param [SpanContext] span_context SpanContext to be wrapped
    #
    # @return [Span]
    def non_recording_span(span_context)
      Span.new(span_context: span_context)
    end
  end
end

require 'opentelemetry/trace/link'
require 'opentelemetry/trace/trace_flags'
require 'opentelemetry/trace/tracestate'
require 'opentelemetry/trace/span_context'
require 'opentelemetry/trace/span_kind'
require 'opentelemetry/trace/span'
require 'opentelemetry/trace/status'
require 'opentelemetry/trace/propagation'
require 'opentelemetry/trace/tracer'
require 'opentelemetry/trace/tracer_provider'
