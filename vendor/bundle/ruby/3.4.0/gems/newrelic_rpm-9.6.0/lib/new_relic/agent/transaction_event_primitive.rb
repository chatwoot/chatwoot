# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# This module was introduced and largely extracted from the transaction event aggregator
# when the synthetics container was extracted from it. Its purpose is to create the data
# necessary for creating a transaction event and to facilitate transfer of events between
# the transaction event aggregator and the synthetics container.

require 'new_relic/agent/payload_metric_mapping'
require 'new_relic/agent/distributed_tracing/distributed_trace_attributes'

module NewRelic
  module Agent
    module TransactionEventPrimitive
      include NewRelic::Coerce
      extend self

      COMMA = ','

      # The type field of the sample
      SAMPLE_TYPE = 'Transaction'

      # Strings for static keys of the sample structure
      TYPE_KEY = 'type'
      TIMESTAMP_KEY = 'timestamp'
      NAME_KEY = 'name'
      DURATION_KEY = 'duration'
      ERROR_KEY = 'error'
      SAMPLED_KEY = 'sampled'
      PRIORITY_KEY = 'priority'
      GUID_KEY = 'nr.guid'
      REFERRING_TRANSACTION_GUID_KEY = 'nr.referringTransactionGuid'
      CAT_PATH_HASH_KEY = 'nr.pathHash'
      CAT_REFERRING_PATH_HASH_KEY = 'nr.referringPathHash'
      CAT_ALTERNATE_PATH_HASHES_KEY = 'nr.alternatePathHashes'
      APDEX_PERF_ZONE_KEY = 'nr.apdexPerfZone'
      SYNTHETICS_RESOURCE_ID_KEY = 'nr.syntheticsResourceId'
      SYNTHETICS_JOB_ID_KEY = 'nr.syntheticsJobId'
      SYNTHETICS_MONITOR_ID_KEY = 'nr.syntheticsMonitorId'
      SYNTHETICS_TYPE_KEY = 'nr.syntheticsType'
      SYNTHETICS_INITIATOR_KEY = 'nr.syntheticsInitiator'
      SYNTHETICS_KEY_PREFIX = 'nr.synthetics'

      SYNTHETICS_PAYLOAD_EXPECTED = [:synthetics_resource_id, :synthetics_job_id, :synthetics_monitor_id, :synthetics_type, :synthetics_initiator]

      def create(payload)
        intrinsics = {
          TIMESTAMP_KEY => float(payload[:start_timestamp]),
          NAME_KEY => string(payload[:name]),
          DURATION_KEY => float(payload[:duration]),
          TYPE_KEY => SAMPLE_TYPE,
          ERROR_KEY => payload[:error],
          PRIORITY_KEY => payload[:priority]
        }

        intrinsics[SAMPLED_KEY] = payload[:sampled] if payload.key?(:sampled)

        PayloadMetricMapping.append_mapped_metrics(payload[:metrics], intrinsics)
        append_optional_attributes(intrinsics, payload)
        DistributedTraceAttributes.copy_to_hash(payload, intrinsics)

        attributes = payload[:attributes]

        [intrinsics, custom_attributes(attributes), agent_attributes(attributes)]
      end

      private

      def append_optional_attributes(sample, payload)
        optionally_append(GUID_KEY, :guid, sample, payload)
        optionally_append(REFERRING_TRANSACTION_GUID_KEY, :referring_transaction_guid, sample, payload)
        optionally_append(CAT_PATH_HASH_KEY, :cat_path_hash, sample, payload)
        optionally_append(CAT_REFERRING_PATH_HASH_KEY, :cat_referring_path_hash, sample, payload)
        optionally_append(APDEX_PERF_ZONE_KEY, :apdex_perf_zone, sample, payload)
        optionally_append(SYNTHETICS_RESOURCE_ID_KEY, :synthetics_resource_id, sample, payload)
        optionally_append(SYNTHETICS_JOB_ID_KEY, :synthetics_job_id, sample, payload)
        optionally_append(SYNTHETICS_MONITOR_ID_KEY, :synthetics_monitor_id, sample, payload)
        optionally_append(SYNTHETICS_TYPE_KEY, :synthetics_type, sample, payload)
        optionally_append(SYNTHETICS_INITIATOR_KEY, :synthetics_initiator, sample, payload)
        append_synthetics_info_attributes(sample, payload)
        append_cat_alternate_path_hashes(sample, payload)
      end

      def append_synthetics_info_attributes(sample, payload)
        return unless payload.include?(:synthetics_job_id)

        payload.each do |k, v|
          next unless k.to_s.start_with?('synthetics_') && !SYNTHETICS_PAYLOAD_EXPECTED.include?(k)

          new_key = SYNTHETICS_KEY_PREFIX + NewRelic::LanguageSupport.camelize(k.to_s.gsub('synthetics_', ''))
          sample[new_key] = v.to_s
        end
      end

      def append_cat_alternate_path_hashes(sample, payload)
        if payload.include?(:cat_alternate_path_hashes)
          sample[CAT_ALTERNATE_PATH_HASHES_KEY] = payload[:cat_alternate_path_hashes].sort.join(COMMA)
        end
      end

      def optionally_append(sample_key, payload_key, sample, payload)
        if payload.include?(payload_key)
          sample[sample_key] = string(payload[payload_key])
        end
      end

      def custom_attributes(attributes)
        if attributes
          result = attributes.custom_attributes_for(AttributeFilter::DST_TRANSACTION_EVENTS)
          result.freeze
        else
          NewRelic::EMPTY_HASH
        end
      end

      def agent_attributes(attributes)
        if attributes
          result = attributes.agent_attributes_for(AttributeFilter::DST_TRANSACTION_EVENTS)
          result.freeze
        else
          NewRelic::EMPTY_HASH
        end
      end
    end
  end
end
