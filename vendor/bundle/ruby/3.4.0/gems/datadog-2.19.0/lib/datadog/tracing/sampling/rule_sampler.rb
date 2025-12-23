# frozen_string_literal: true

require_relative 'ext'
require_relative '../../core/rate_limiter'
require_relative 'rule'
require_relative '../../core/telemetry/logger'

module Datadog
  module Tracing
    module Sampling
      # Span {Sampler} that applies a set of {Rule}s to decide
      # on sampling outcome. Then, a rate limiter is applied.
      #
      # If a trace does not conform to any rules, a default
      # sampling strategy is applied.
      class RuleSampler
        attr_reader :rules, :rate_limiter, :default_sampler

        # @param rules [Array<Rule>] ordered list of rules to be applied to a trace
        # @param rate_limit [Float] number of traces per second, defaults to +100+
        # @param rate_limiter [RateLimiter] limiter applied after rule matching
        # @param default_sample_rate [Float] fallback sample rate when no rules apply to a trace,
        #   between +[0,1]+, defaults to +1+
        # @param default_sampler [Sample] fallback strategy when no rules apply to a trace
        def initialize(
          rules = [],
          rate_limit: Datadog.configuration.tracing.sampling.rate_limit,
          rate_limiter: nil,
          default_sample_rate: Datadog.configuration.tracing.sampling.default_rate,
          default_sampler: nil
        )
          @rules = if default_sample_rate && !default_sampler
                     # Add to the end of the rule list a rule always matches any trace
                     rules << SimpleRule.new(sample_rate: default_sample_rate)
                   else
                     rules
                   end
          @rate_limiter = if rate_limiter
                            rate_limiter
                          elsif rate_limit
                            Core::TokenBucket.new(rate_limit)
                          else
                            Core::UnlimitedLimiter.new
                          end
          @default_sampler = if default_sampler
                               default_sampler
                             elsif default_sample_rate
                               nil
                             else
                               # TODO: Simplify .tags access, as `Tracer#tags` can't be arbitrarily changed anymore
                               RateByServiceSampler.new(1.0, env: -> { Tracing.send(:tracer).tags['env'] })
                             end
        end

        def self.parse(rules, rate_limit, default_sample_rate)
          parsed_rules = JSON.parse(rules).map do |rule|
            sample_rate = rule['sample_rate']

            begin
              sample_rate = Float(sample_rate)
            rescue
              raise "Rule '#{rule.inspect}' does not contain a float property `sample_rate`"
            end

            kwargs = {
              name: rule['name'],
              service: rule['service'],
              resource: rule['resource'],
              tags: rule['tags'],
              sample_rate: sample_rate,
              provenance: if (provenance = rule['provenance'])
                            # `Rule::PROVENANCE_*` values are symbols, so convert strings to match
                            provenance.to_sym
                          else
                            Rule::PROVENANCE_LOCAL
                          end,
            }

            kwargs.compact!

            SimpleRule.new(**kwargs)
          end

          new(parsed_rules, rate_limit: rate_limit, default_sample_rate: default_sample_rate)
        rescue => e
          Datadog.logger.warn do
            "Could not parse trace sampling rules '#{rules}': #{e.class.name} #{e.message} at #{Array(e.backtrace).first}"
          end

          nil
        end

        def sample!(trace)
          sampled = sample_trace(trace) do |t|
            @default_sampler.sample!(t).tap do
              # We want to make sure the trace is tagged with the agent-derived
              # service rate. Retrieve this from the rate by service sampler.
              # Only do this if it was set by a RateByServiceSampler.
              trace.agent_sample_rate = @default_sampler.sample_rate(trace) if @default_sampler.is_a?(RateByServiceSampler)
            end
          end

          trace.sampled = sampled
        end

        # @!visibility private
        def update(*args, **kwargs)
          return false unless @default_sampler.respond_to?(:update)

          @default_sampler.update(*args, **kwargs)
        end

        private

        def sample_trace(trace)
          rule = @rules.find { |r| r.match?(trace) }

          return yield(trace) if rule.nil?

          sampled = rule.sample!(trace)
          sample_rate = rule.sample_rate(trace)

          set_priority(trace, sampled)
          set_rule_metrics(trace, sample_rate)

          return false unless sampled

          rate_limiter.allow?.tap do |allowed|
            set_priority(trace, allowed)
            set_limiter_metrics(trace, rate_limiter.effective_rate)

            provenance = case rule.provenance
                         when Rule::PROVENANCE_REMOTE_USER
                           Ext::Decision::REMOTE_USER_RULE
                         when Rule::PROVENANCE_REMOTE_DYNAMIC
                           Ext::Decision::REMOTE_DYNAMIC_RULE
                         else
                           Ext::Decision::TRACE_SAMPLING_RULE
                         end

            trace.set_tag(Tracing::Metadata::Ext::Distributed::TAG_DECISION_MAKER, provenance)
          end
        rescue StandardError => e
          Datadog.logger.error(
            "Rule sampling failed. Cause: #{e.class.name} #{e.message} Source: #{Array(e.backtrace).first}"
          )
          Datadog::Core::Telemetry::Logger.report(e, description: 'Rule sampling failed')

          yield(trace)
        end

        # Span priority should only be set when the {RuleSampler}
        # was responsible for the sampling decision.
        def set_priority(trace, sampled)
          trace.sampling_priority = if sampled
                                      Sampling::Ext::Priority::USER_KEEP
                                    else
                                      Sampling::Ext::Priority::USER_REJECT
                                    end
        end

        def set_rule_metrics(trace, sample_rate)
          trace.rule_sample_rate = sample_rate
        end

        def set_limiter_metrics(trace, limiter_rate)
          trace.rate_limiter_rate = limiter_rate
        end
      end
    end
  end
end
