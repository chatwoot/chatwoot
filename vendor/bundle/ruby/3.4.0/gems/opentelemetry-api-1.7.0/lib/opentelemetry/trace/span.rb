# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # Span represents a single operation within a trace. Spans can be nested to
    # form a trace tree. Often, a trace contains a root span that describes the
    # end-to-end latency and, optionally, one or more sub-spans for its
    # sub-operations.
    #
    # Once Span {Tracer#start_span is created} - Span operations can be used to
    # add additional properties to it like attributes, links, events, name and
    # resulting status. Span cannot be used to retrieve these properties. This
    # prevents the mis-use of spans as an in-process information propagation
    # mechanism.
    #
    # {Span} must be ended by calling {#finish}.
    class Span
      # Retrieve the spans SpanContext
      #
      # The returned value may be used even after the Span is finished.
      #
      # @return [SpanContext]
      attr_reader :context

      # Spans must be created using {Tracer}. This is for internal use only.
      #
      # @api private
      def initialize(span_context: nil)
        @context = span_context || SpanContext.new
      end

      # Return whether this span is recording.
      #
      # @return [Boolean] true if this Span is active and recording information
      #   like events with the #add_event operation and attributes using
      #   #set_attribute.
      def recording?
        false
      end

      # Set attribute
      #
      # Note that the OpenTelemetry project
      # {https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-semantic-conventions.md
      # documents} certain "standard attributes" that have prescribed semantic
      # meanings.
      #
      # @param [String] key
      # @param [String, Boolean, Numeric, Array<String, Numeric, Boolean>] value
      #   Values must be non-nil and (array of) string, boolean or numeric type.
      #   Array values must not contain nil elements and all elements must be of
      #   the same basic type (string, numeric, boolean).
      #
      # @return [self] returns itself
      def set_attribute(key, value)
        self
      end
      alias []= set_attribute

      # Add attributes
      #
      # Note that the OpenTelemetry project
      # {https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-semantic-conventions.md
      # documents} certain "standard attributes" that have prescribed semantic
      # meanings.
      #
      # @param [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
      #   Values must be non-nil and (array of) string, boolean or numeric type.
      #   Array values must not contain nil elements and all elements must be of
      #   the same basic type (string, numeric, boolean).
      #
      # @return [self] returns itself
      def add_attributes(attributes)
        self
      end

      # Add a link to a {Span}.
      #
      # Adding links at span creation using the `links` option is preferred
      # to calling add_link later, because head sampling decisions can only
      # consider information present during span creation.
      #
      # Example:
      #
      #   span.add_link(OpenTelemetry::Trace::Link.new(span_to_link_from.context))
      #
      # Note that the OpenTelemetry project
      # {https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-semantic-conventions.md
      # documents} certain "standard attributes" that have prescribed semantic
      # meanings.
      #
      # @param [OpenTelemetry::Trace::Link] the link object to add on the {Span}.
      #
      # @return [self] returns itself
      def add_link(link)
        self
      end

      # Add an event to a {Span}.
      #
      # Example:
      #
      #   span.add_event('event', attributes: {'eager' => true})
      #
      # Note that the OpenTelemetry project
      # {https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/data-semantic-conventions.md
      # documents} certain "standard event names and keys" which have
      # prescribed semantic meanings.
      #
      # @param [String] name Name of the event.
      # @param [optional Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}]
      #   attributes One or more key:value pairs, where the keys must be
      #   strings and the values may be (array of) string, boolean or numeric
      #   type.
      # @param [optional Time] timestamp Optional timestamp for the event.
      #
      # @return [self] returns itself
      def add_event(name, attributes: nil, timestamp: nil)
        self
      end

      # Record an exception during the execution of this span. Multiple exceptions
      # can be recorded on a span.
      #
      # @param [Exception] exception The exception to recorded
      # @param [optional Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}]
      #   attributes One or more key:value pairs, where the keys must be
      #   strings and the values may be (array of) string, boolean or numeric
      #   type.
      #
      # @return [void]
      def record_exception(exception, attributes: nil); end

      # Sets the Status to the Span
      #
      # If used, this will override the default Span status. Default status is unset.
      #
      # Only the value of the last call will be recorded, and implementations
      # are free to ignore previous calls.
      #
      # @param [Status] status The new status, which overrides the default Span
      #   status, which is OK.
      #
      # @return [void]
      def status=(status); end

      # Updates the Span name
      #
      # Upon this update, any sampling behavior based on Span name will depend
      # on the implementation.
      #
      # @param [String] new_name The new operation name, which supersedes
      #   whatever was passed in when the Span was started
      #
      # @return [void]
      def name=(new_name); end

      # Finishes the Span
      #
      # Implementations MUST ignore all subsequent calls to {#finish} (there
      # might be exceptions when Tracer is streaming event and has no mutable
      # state associated with the Span).
      #
      # Call to {#finish} MUST not have any effects on child spans. Those may
      # still be running and can be ended later.
      #
      # This API MUST be non-blocking.
      #
      # @param [Time] end_timestamp optional end timestamp for the span.
      #
      # @return [self] returns itself
      def finish(end_timestamp: nil)
        self
      end

      INVALID = new(span_context: SpanContext::INVALID)
    end
  end
end
