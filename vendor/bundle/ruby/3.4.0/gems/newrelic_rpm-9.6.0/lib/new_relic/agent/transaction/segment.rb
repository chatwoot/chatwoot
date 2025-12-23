# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/transaction/abstract_segment'
require 'new_relic/agent/span_event_primitive'
require 'new_relic/agent/attributes'

module NewRelic
  module Agent
    class Transaction
      class Segment < AbstractSegment
        # unscoped_metrics can be nil, a string, or array. we do this to save
        # object allocations. if allocations weren't important then we would
        # initialize it as an array that would be empty, have one item, or many items.
        attr_reader :unscoped_metrics, :custom_transaction_attributes

        def initialize(name = nil, unscoped_metrics = nil, start_time = nil)
          @unscoped_metrics = unscoped_metrics
          super(name, start_time)
        end

        def attributes
          @attributes ||= Attributes.new(NewRelic::Agent.instance.attribute_filter)
        end

        def add_agent_attribute(key, value, default_destinations = AttributeFilter::DST_SPAN_EVENTS)
          attributes.add_agent_attribute(key, value, default_destinations)
        end

        def self.merge_untrusted_agent_attributes(attributes, prefix, default_destinations)
          if segment = NewRelic::Agent::Tracer.current_segment
            segment.merge_untrusted_agent_attributes(attributes, prefix, default_destinations)
          else
            NewRelic::Agent.logger.debug('Attempted to merge untrusted attributes without segment')
          end
        end

        def merge_untrusted_agent_attributes(agent_attributes, prefix, default_destinations)
          return if agent_attributes.nil?

          attributes.merge_untrusted_agent_attributes(agent_attributes, prefix, default_destinations)
        end

        def add_custom_attributes(p)
          attributes.merge_custom_attributes(p)
        end

        def self.finish(segment)
          return unless segment

          segment.finish
        end

        private

        def record_metrics
          if record_scoped_metric?
            metric_cache.record_scoped_and_unscoped(name, duration, exclusive_duration)
          else
            append_unscoped_metric(name)
          end
          if unscoped_metrics
            metric_cache.record_unscoped(unscoped_metrics, duration, exclusive_duration)
          end
        end

        def append_unscoped_metric(metric)
          if @unscoped_metrics
            if Array === @unscoped_metrics
              if unscoped_metrics.frozen?
                @unscoped_metrics += [name]
              else
                @unscoped_metrics << name
              end
            else
              @unscoped_metrics = [@unscoped_metrics, metric]
            end
          else
            @unscoped_metrics = metric
          end
        end

        def segment_complete
          record_span_event if transaction.sampled?
        end

        def record_span_event
          # don't record a span event if the transaction is ignored
          return if transaction.ignore?

          aggregator = ::NewRelic::Agent.agent.span_event_aggregator
          priority = transaction.priority

          aggregator.record(priority: priority) do
            SpanEventPrimitive.for_segment(self)
          end
        end
      end
    end
  end
end
