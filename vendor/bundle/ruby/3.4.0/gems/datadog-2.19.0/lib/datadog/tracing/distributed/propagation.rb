# frozen_string_literal: true

require_relative '../configuration/ext'
require_relative '../trace_digest'
require_relative '../trace_operation'
require_relative '../../core/telemetry/logger'
require_relative 'baggage'

module Datadog
  module Tracing
    module Distributed
      # Provides extraction and injection of distributed trace data.
      class Propagation
        # @param propagation_styles [Hash<String,Object>]
        #  a map of propagation styles to their corresponding implementations
        # @param propagation_style_inject [Array<String>]
        #   a list of styles to use when injecting distributed trace data
        # @param propagation_style_extract [Array<String>]
        #   a list of styles to use when extracting distributed trace data
        # @param propagation_extract_first [Boolean]
        #   if true, only the first successfully extracted trace will be used
        def initialize(
          propagation_styles:,
          propagation_style_inject:,
          propagation_style_extract:,
          propagation_extract_first:
        )
          @propagation_styles = propagation_styles
          @propagation_extract_first = propagation_extract_first
          @propagation_style_inject = propagation_style_inject.map { |style| propagation_styles[style] }
          @propagation_style_extract = propagation_style_extract.map { |style| propagation_styles[style] }

          # The baggage propagator is unique in that baggage should always be extracted, if present.
          # Therefore we remove it from the `propagation_style_extract` list.
          @baggage_propagator = @propagation_style_extract.find { |propagator| propagator.is_a?(Baggage) }
          @propagation_style_extract.delete(@baggage_propagator) if @baggage_propagator
        end

        # inject! populates the env with span ID, trace ID and sampling priority
        #
        # This method will never raise errors.
        # It can propagate partial data, if deemed useful, instead of failing.
        # In case of unrecoverable errors, it will log them to `Datadog.logger`.
        #
        # DEV-2.0: inject! should work without arguments, injecting the active_trace's digest
        # DEV-2.0: and returning a new Hash with the injected data.
        # DEV-2.0: inject! should also accept either a `trace` or a `digest`, as a `trace`
        # DEV-2.0: argument is the common use case, but also allows us to set error tags in the `trace`
        # DEV-2.0: if needed.
        # DEV-2.0: Ideally, we'd have a separate stream to report tracer errors and never
        # DEV-2.0: touch the active span.
        # DEV-3.0: Sample trace here instead of when generating digest.
        #
        # @param digest [TraceDigest]
        # @param data [Hash]
        # @return [Boolean] `true` if injected successfully, `false` if no propagation style is configured
        # @return [nil] in case of unrecoverable errors, see `Datadog.logger` output for details.
        def inject!(digest, data)
          if digest.nil?
            ::Datadog.logger.debug('Cannot inject distributed trace data: digest is nil.')
            return nil
          end

          digest = digest.to_digest if digest.respond_to?(:to_digest)
          if digest.trace_id.nil? && digest.baggage.nil?
            ::Datadog.logger.debug('Cannot inject distributed trace data: digest.trace_id and digest.baggage are both nil.')
            return nil
          end

          result = false

          # Inject all configured propagation styles
          @propagation_style_inject.each do |propagator|
            propagator.inject!(digest, data)
            result = true
          rescue => e
            result = nil
            ::Datadog.logger.error(
              "Error injecting distributed trace data. Cause: #{e} Location: #{Array(e.backtrace).first}"
            )
            ::Datadog::Core::Telemetry::Logger.report(
              e,
              description: "Error injecting distributed trace data with #{propagator.class.name}"
            )
          end

          result
        end

        # extract returns {TraceDigest} containing the distributed trace information.
        # sampling priority defined in data.
        #
        # This method will never raise errors, but instead log them to `Datadog.logger`.
        #
        # @param data [Hash]
        def extract(data)
          return unless data
          return if data.empty?

          extracted_trace_digest = nil

          @propagation_style_extract.each do |propagator|
            # First extraction?
            unless extracted_trace_digest
              extracted_trace_digest = propagator.extract(data)
              next
            end

            # Return if we are only inspecting the first valid style.
            next if @propagation_extract_first

            # Continue parsing styles to find the W3C `tracestate` header, if present.
            # `tracestate` must always be propagated, as it might contain pass-through data that we don't control.
            # @see https://www.w3.org/TR/2021/REC-trace-context-1-20211123/#mutating-the-tracestate-field
            next unless propagator.is_a?(TraceContext)

            if (tracecontext_digest = propagator.extract(data))
              # Only parse if it represent the same trace as the successfully extracted one
              next unless tracecontext_digest.trace_id == extracted_trace_digest.trace_id

              parent_id = extracted_trace_digest.span_id
              distributed_tags = extracted_trace_digest.trace_distributed_tags
              unless extracted_trace_digest.span_id == tracecontext_digest.span_id
                # span_id in the tracecontext header takes precedence over the value in all conflicting headers
                parent_id = tracecontext_digest.span_id
                if (lp_id = last_datadog_parent_id(data, tracecontext_digest.trace_distributed_tags))
                  distributed_tags = extracted_trace_digest.trace_distributed_tags&.dup || {}
                  distributed_tags[Tracing::Metadata::Ext::Distributed::TAG_DD_PARENT_ID] = lp_id
                end
              end
              # Preserve the trace state and last datadog span id
              extracted_trace_digest = extracted_trace_digest.merge(
                span_id: parent_id,
                trace_state: tracecontext_digest.trace_state,
                trace_state_unknown_fields: tracecontext_digest.trace_state_unknown_fields,
                trace_distributed_tags: distributed_tags
              )
            end
          rescue => e
            # TODO: Not to report Telemetry logs for now
            ::Datadog.logger.error(
              "Error extracting distributed trace data. Cause: #{e} Location: #{Array(e.backtrace).first}"
            )
          end
          # Handle baggage after all other styles if present
          extracted_trace_digest = propagate_baggage(data, extracted_trace_digest) if @baggage_propagator

          extracted_trace_digest
        end

        private

        def propagate_baggage(data, extracted_trace_digest)
          if extracted_trace_digest
            # Merge with baggage if present
            digest = @baggage_propagator.extract(data)
            if digest
              extracted_trace_digest.merge(baggage: digest.baggage)
            else
              extracted_trace_digest
            end
          else
            # Baggage is the only style
            @baggage_propagator.extract(data)
          end
        end

        def last_datadog_parent_id(headers, tracecontext_tags)
          dd_propagator = @propagation_style_extract.find { |propagator| propagator.is_a?(Datadog) }
          if tracecontext_tags&.fetch(
            Tracing::Metadata::Ext::Distributed::TAG_DD_PARENT_ID,
            Tracing::Metadata::Ext::Distributed::DD_PARENT_ID_DEFAULT
          ) != Tracing::Metadata::Ext::Distributed::DD_PARENT_ID_DEFAULT
            # tracecontext headers contain a p value, ensure this value is sent to backend
            tracecontext_tags[Tracing::Metadata::Ext::Distributed::TAG_DD_PARENT_ID]
          elsif dd_propagator && (dd_digest = dd_propagator.extract(headers))
            # if p value is not present in tracestate, use the parent id from the datadog headers
            format('%016x', dd_digest.span_id)
          end
        end
      end
    end
  end
end
