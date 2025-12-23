# frozen_string_literal: true

require_relative 'ext'

module Datadog
  module Tracing
    module Sampling
      module Span
        # Span sampling rule that applies a sampling rate if the span
        # matches the provided {Matcher}.
        # Additionally, a rate limiter is also applied.
        #
        # If a span does not conform to the matcher, no changes are made.
        class Rule
          attr_reader :matcher, :sample_rate, :rate_limit

          # Creates a new span sampling rule.
          #
          # @param [Sampling::Span::Matcher] matcher whether this rule applies to a specific span
          # @param [Float] sample_rate span sampling ratio, between 0.0 (0%) and 1.0 (100%).
          # @param [Numeric] rate_limit maximum number of spans sampled per second. Negative numbers mean unlimited spans.
          def initialize(
            matcher,
            sample_rate: Span::Ext::DEFAULT_SAMPLE_RATE,
            rate_limit: Span::Ext::DEFAULT_MAX_PER_SECOND
          )
            @matcher = matcher
            @sample_rate = sample_rate
            @rate_limit = rate_limit

            @sampler = Sampling::RateSampler.new(sample_rate)
            @rate_limiter = Core::TokenBucket.new(rate_limit)
          end

          # This method should only be invoked for spans that are part
          # of a trace that has been dropped by trace-level sampling.
          # Invoking it for other spans will cause incorrect sampling
          # metrics to be reported by the Datadog App.
          #
          # Returns `true` if the provided span is sampled.
          # If the span is dropped due to sampling rate or rate limiting,
          # it returns `false`.
          #
          # Returns `nil` if the span did not meet the matching criteria by the
          # provided matcher.
          #
          # This method modifies the `span` if it matches the provided matcher.
          #
          # @param [Datadog::Tracing::TraceOperation] trace_op trace for the span to be sampled
          # @param [Datadog::Tracing::SpanOperation] span_op span to be sampled
          # @return [:kept,:rejected] should this span be sampled?
          # @return [:not_matched] span did not satisfy the matcher, no changes are made to the span
          def sample!(trace_op, span_op)
            return :not_matched unless @matcher.match?(span_op)

            if @rate_limiter.allow? && @sampler.sample!(trace_op)
              span_op.set_metric(Span::Ext::TAG_MECHANISM, Sampling::Ext::Mechanism::SPAN_SAMPLING_RATE)
              span_op.set_metric(Span::Ext::TAG_RULE_RATE, @sample_rate)
              span_op.set_metric(Span::Ext::TAG_MAX_PER_SECOND, @rate_limit)
              :kept
            else
              :rejected
            end
          end

          def ==(other)
            return super unless other.is_a?(Rule)

            matcher == other.matcher &&
              sample_rate == other.sample_rate &&
              rate_limit == other.rate_limit
          end
        end
      end
    end
  end
end
