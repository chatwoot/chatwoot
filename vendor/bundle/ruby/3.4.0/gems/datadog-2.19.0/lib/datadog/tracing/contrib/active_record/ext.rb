# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module ActiveRecord
        # ActiveRecord integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_ACTIVE_RECORD_ENABLED'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_ACTIVE_RECORD_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_ACTIVE_RECORD_ANALYTICS_SAMPLE_RATE'
          SERVICE_NAME = 'active_record'
          SPAN_INSTANTIATION = 'active_record.instantiation'
          SPAN_SQL = 'active_record.sql'
          SPAN_TYPE_INSTANTIATION = 'custom'
          TAG_COMPONENT = 'active_record'
          TAG_OPERATION_INSTANTIATION = 'instantiation'
          TAG_OPERATION_SQL = 'sql'
          TAG_DB_CACHED = 'active_record.db.cached'
          TAG_DB_NAME = 'active_record.db.name'
          TAG_DB_VENDOR = 'active_record.db.vendor'
          TAG_INSTANTIATION_CLASS_NAME = 'active_record.instantiation.class_name'
          TAG_INSTANTIATION_RECORD_COUNT = 'active_record.instantiation.record_count'
        end
      end
    end
  end
end
