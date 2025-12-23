# frozen_string_literal: true

require_relative 'trace/span'
require_relative '../../tracing/span_link'
require_relative '../../tracing/span_event'
require_relative '../../tracing/trace_digest'

module Datadog
  module OpenTelemetry
    module SDK
      # Keeps OpenTelemetry spans in sync with the Datadog execution context.
      # Also responsible for flushing spans when their are finished.
      class SpanProcessor
        # Called when a {Span} is started, if the {Span#recording?}
        # returns true.
        #
        # This method is called synchronously on the execution thread, should
        # not throw or block the execution thread.
        #
        # @param [Span] span the {Span} that just started.
        # @param [Context] parent_context the parent {Context} of the newly
        #  started span.
        def on_start(span, parent_context)
          create_matching_datadog_span(span, parent_context)
        end

        # Called when a {Span} is ended, if the {Span#recording?}
        # returns true.
        #
        # This method is called synchronously on the execution thread, should
        # not throw or block the execution thread.
        #
        # @param [Span] span the {Span} that just ended.
        def on_finish(span)
          unless span.events.nil?
            span.datadog_span.span_events = span.events.map do |event|
              Datadog::Tracing::SpanEvent.new(
                event.name,
                attributes: event.attributes,
                time_unix_nano: event.timestamp
              )
            end
          end
          span.datadog_span.finish(ns_to_time(span.end_timestamp))
        end

        # Export all ended spans to the configured `Exporter` that have not yet
        # been exported.
        #
        # This method should only be called in cases where it is absolutely
        # necessary, such as when using some FaaS providers that may suspend
        # the process after an invocation, but before the `Processor` exports
        # the completed spans.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def force_flush(timeout: nil)
          writer.force_flush(timeout: timeout) if writer.respond_to? :force_flush
          Export::SUCCESS
        end

        # Called when {TracerProvider#shutdown} is called.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def shutdown(timeout: nil)
          writer.stop
          Export::SUCCESS
        end

        private

        def writer
          Datadog.configuration.tracing.writer
        end

        def create_matching_datadog_span(span, parent_context)
          if parent_context.trace
            Tracing.send(:tracer).send(:call_context).activate!(parent_context.ensure_trace)
          else
            otel_trace_id = span.context.hex_trace_id.to_i(16)
            Tracing.continue_trace!(Datadog::Tracing::TraceDigest.new(trace_id: otel_trace_id, span_remote: false))
          end

          datadog_span = start_datadog_span(span)

          span.datadog_span = datadog_span
          span.datadog_trace = Tracing.active_trace
        end

        def start_datadog_span(span)
          attributes = span.attributes.dup # Dup to allow modification of frozen Hash

          name, kwargs = span_arguments(span, attributes)

          datadog_span = Tracing.trace(name, **kwargs)
          datadog_span.set_error([nil, span.status.description]) unless span.status.ok?
          datadog_span.set_tags(span.attributes)

          unless span.links.nil?
            datadog_span.links = span.links.map do |link|
              Datadog::Tracing::SpanLink.new(
                Datadog::Tracing::TraceDigest.new(
                  trace_id: link.span_context.hex_trace_id.to_i(16),
                  span_id: link.span_context.hex_span_id.to_i(16),
                  trace_sampling_priority: (link.span_context.trace_flags&.sampled? ? 1 : 0),
                  trace_state: link.span_context.tracestate&.to_s,
                  span_remote: link.span_context.remote?,
                ),
                attributes: link.attributes
              )
            end
          end

          datadog_span
        end

        # Some special attributes can override Datadog Span fields
        def span_arguments(span, attributes)
          if attributes.key?('analytics.event') && (analytics_event = attributes['analytics.event']).respond_to?(:casecmp)
            attributes[Tracing::Metadata::Ext::Analytics::TAG_SAMPLE_RATE] = analytics_event.casecmp('true') == 0 ? 1 : 0
          end

          if attributes.key?('http.response.status_code')
            attributes[Tracing::Metadata::Ext::HTTP::TAG_STATUS_CODE] = attributes.delete('http.response.status_code')
          end

          attributes[Tracing::Metadata::Ext::TAG_KIND] = span.kind || 'internal'

          kwargs = { start_time: ns_to_time(span.start_timestamp) }

          name = if attributes.key?('operation.name')
                   attributes['operation.name']
                 elsif (rich_name = Datadog::OpenTelemetry::Trace::Span.enrich_name(span.kind, attributes))
                   rich_name.downcase
                 else
                   span.kind
                 end

          kwargs[:resource] = attributes.key?('resource.name') ? attributes['resource.name'] : span.name
          kwargs[:service] = attributes['service.name'] if attributes.key?('service.name')
          kwargs[:type] = attributes['span.type'] if attributes.key?('span.type')

          attributes.reject! { |key, _| OpenTelemetry::Trace::Span::DATADOG_SPAN_ATTRIBUTE_OVERRIDES.include?(key) }

          # DEV: There's no `flat_map!`; we have to split it into two operations
          attributes = attributes.map do |key, value|
            Datadog::Tracing::Utils.serialize_attribute(key, value)
          end
          attributes.flatten!(1)

          kwargs[:tags] = attributes.to_h

          # DEV: The datadog span must have the same ID as the OpenTelemetry span
          kwargs[:id] = span.context.hex_span_id.to_i(16)

          [name, kwargs]
        end

        # From nanoseconds, used by OpenTelemetry, to a {Time} object, used by the Datadog Tracer.
        def ns_to_time(timestamp_ns)
          Time.at(timestamp_ns / 1000000000.0)
        end
      end
    end
  end
end
