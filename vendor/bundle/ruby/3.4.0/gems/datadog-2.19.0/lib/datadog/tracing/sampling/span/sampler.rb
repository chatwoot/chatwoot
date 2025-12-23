# frozen_string_literal: true

module Datadog
  module Tracing
    module Sampling
      module Span
        # Applies Single Span Sampling rules to spans.
        # When matching the configured rules, a span is ensured to
        # be processed Datadog App. In other words, a single sampled span
        # will never be dropped by the tracer or Datadog agent.
        #
        # All spans in a trace are subject to the single sampling rules, if
        # any rules are configured.
        #
        # Single Span Sampling is distinct from trace-level sampling:
        # Single Span Sampling can ensure a span is kept, even if its
        # enclosing trace is rejected by trace-level sampling.
        #
        # This class only applies operations to spans that are part
        # of traces that was rejected by trace sampling.
        # A trace is rejected if either of the following conditions is true:
        # * The priority sampling for a trace is set to either {USER_REJECT} or {AUTO_REJECT}.
        # * The trace was rejected by internal sampling, thus never flushed.
        #
        # Single-sampled spans are tagged and the tracer ensures they will
        # reach the Datadog App, regardless of their enclosing trace sampling decision.
        #
        # Single Span Sampling does not inspect spans that are part of a trace
        # that has been accepted by trace-level sampling rules: all spans from such
        # trace are guaranteed to reach the Datadog App.
        class Sampler
          attr_reader :rules

          # Receives sampling rules to apply to individual spans.
          #
          # @param [Array<Datadog::Tracing::Sampling::Span::Rule>] rules list of rules to apply to spans
          def initialize(rules = [])
            @rules = rules
          end

          # Applies Single Span Sampling rules to the span if the trace has been rejected.
          #
          # The trace can be outright rejected, and never reach the transport,
          # or be set as rejected by priority sampling. In both cases, the trace
          # is considered rejected for Single Span Sampling purposes.
          #
          # If multiple rules match, only the first one is applied.
          #
          # @param [Datadog::Tracing::TraceOperation] trace_op trace for the provided span
          # @param [Datadog::Tracing::SpanOperation] span_op Span to apply sampling rules
          # @return [void]
          def sample!(trace_op, span_op)
            return if trace_op.sampled? && trace_op.priority_sampled?

            # Applies the first matching rule
            @rules.each do |rule|
              decision = rule.sample!(trace_op, span_op)

              next if decision == :not_matched # Iterate until we find a matching decision

              if decision == :kept
                trace_op.set_tag(
                  Metadata::Ext::Distributed::TAG_DECISION_MAKER,
                  Sampling::Ext::Decision::SPAN_SAMPLING_RATE
                )
              end

              break # Found either a `kept` or `rejected` decision
            end

            nil
          end
        end
      end
    end
  end
end
