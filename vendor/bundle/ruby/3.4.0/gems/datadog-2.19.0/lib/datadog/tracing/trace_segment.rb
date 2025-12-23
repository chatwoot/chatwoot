# frozen_string_literal: true

require_relative '../core/runtime/ext'
require_relative '../core/utils/safe_dup'

require_relative 'sampling/ext'
require_relative 'metadata/ext'
require_relative 'metadata/tagging'
require_relative 'utils'

module Datadog
  module Tracing
    # Serializable construct representing a trace
    # @public_api
    class TraceSegment
      TAG_NAME = 'name'
      TAG_RESOURCE = 'resource'
      TAG_SERVICE = 'service'

      attr_reader \
        :id,
        :spans,
        :agent_sample_rate,
        :hostname,
        :lang,
        :name,
        :origin,
        :process_id,
        :rate_limiter_rate,
        :resource,
        :rule_sample_rate,
        :runtime_id,
        :sample_rate,
        :sampling_decision_maker,
        :sampling_priority,
        :service,
        :profiling_enabled,
        :apm_tracing_enabled

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      # @param spans [Array<Datadog::Span>]
      def initialize(
        spans,
        agent_sample_rate: nil,
        hostname: nil,
        id: nil,
        lang: nil,
        name: nil,
        origin: nil,
        process_id: nil,
        rate_limiter_rate: nil,
        resource: nil,
        root_span_id: nil,
        rule_sample_rate: nil,
        runtime_id: nil,
        sample_rate: nil,
        sampling_priority: nil,
        service: nil,
        tags: nil,
        metrics: nil,
        profiling_enabled: nil,
        apm_tracing_enabled: nil
      )
        @id = id
        @root_span_id = root_span_id
        @spans = spans || []

        # Does not make an effort to move metrics out of tags
        # The caller is expected to have done that
        @meta = (tags && tags.dup) || {}
        @metrics = (metrics && metrics.dup) || {}

        # Set well-known tags, defaulting to getting the values from tags
        @agent_sample_rate = agent_sample_rate || agent_sample_rate_tag
        @hostname = hostname || hostname_tag
        @lang = lang || lang_tag
        @name = Core::Utils::SafeDup.frozen_or_dup(name || name_tag)
        @origin = Core::Utils::SafeDup.frozen_or_dup(origin || origin_tag)
        @process_id = process_id || process_id_tag
        @rate_limiter_rate = rate_limiter_rate || rate_limiter_rate_tag
        @resource = Core::Utils::SafeDup.frozen_or_dup(resource || resource_tag)
        @rule_sample_rate = rule_sample_rate_tag || rule_sample_rate
        @runtime_id = runtime_id || runtime_id_tag
        @sample_rate = sample_rate || sample_rate_tag
        @sampling_decision_maker = sampling_decision_maker_tag
        @sampling_priority = sampling_priority || sampling_priority_tag
        @service = Core::Utils::SafeDup.frozen_or_dup(service || service_tag)
        @profiling_enabled = profiling_enabled
        @apm_tracing_enabled = apm_tracing_enabled
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity

      def any?
        @spans.any?
      end

      def count
        @spans.count
      end

      def empty?
        @spans.empty?
      end

      def length
        @spans.length
      end

      def size
        @spans.size
      end

      # If an active trace is present, forces it to be retained by the Datadog backend.
      #
      # Any sampling logic will not be able to change this decision.
      #
      # @return [void]
      def keep!
        self.sampling_priority = Sampling::Ext::Priority::USER_KEEP
      end

      # If an active trace is present, forces it to be dropped and not stored by the Datadog backend.
      #
      # Any sampling logic will not be able to change this decision.
      #
      # @return [void]
      def reject!
        self.sampling_priority = Sampling::Ext::Priority::USER_REJECT
      end

      def sampled?
        [Sampling::Ext::Priority::AUTO_KEEP, Sampling::Ext::Priority::USER_KEEP].include?(sampling_priority)
      end

      # Returns the high order part of the trace id as a hexadecimal string; the most significant 64 bits.
      # The String returned is padded with zeros, having a fixed length of 16 characters.
      # If the high order part is zero, it returns nil.
      def high_order_tid
        high_order = Tracing::Utils::TraceId.to_high_order(@id)

        format('%016x', high_order) if high_order != 0
      end

      protected

      attr_reader \
        :root_span_id,
        :meta,
        :metrics

      private

      attr_writer \
        :agent_sample_rate,
        :hostname,
        :lang,
        :name,
        :origin,
        :process_id,
        :rate_limiter_rate,
        :resource,
        :rule_sample_rate,
        :runtime_id,
        :sample_rate,
        :sampling_priority,
        :service

      def agent_sample_rate_tag
        metrics[Metadata::Ext::Sampling::TAG_AGENT_RATE]
      end

      def hostname_tag
        meta[Metadata::Ext::NET::TAG_HOSTNAME]
      end

      def lang_tag
        meta[Core::Runtime::Ext::TAG_LANG]
      end

      def name_tag
        meta[TAG_NAME]
      end

      def origin_tag
        meta[Metadata::Ext::Distributed::TAG_ORIGIN]
      end

      def process_id_tag
        meta[Core::Runtime::Ext::TAG_PROCESS_ID]
      end

      def rate_limiter_rate_tag
        metrics[Metadata::Ext::Sampling::TAG_RATE_LIMITER_RATE]
      end

      def resource_tag
        meta[TAG_RESOURCE]
      end

      def rule_sample_rate_tag
        metrics[Metadata::Ext::Sampling::TAG_RULE_SAMPLE_RATE]
      end

      def runtime_id_tag
        meta[Core::Runtime::Ext::TAG_ID]
      end

      def sample_rate_tag
        metrics[Metadata::Ext::Sampling::TAG_SAMPLE_RATE]
      end

      def sampling_decision_maker_tag
        meta[Metadata::Ext::Distributed::TAG_DECISION_MAKER]
      end

      def sampling_priority_tag
        meta[Metadata::Ext::Distributed::TAG_SAMPLING_PRIORITY]
      end

      def service_tag
        meta[TAG_SERVICE]
      end
    end
  end
end
