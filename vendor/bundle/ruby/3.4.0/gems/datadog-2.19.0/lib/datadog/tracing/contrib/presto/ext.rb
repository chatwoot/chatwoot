# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Presto
        # Presto integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_PRESTO_ENABLED'
          ENV_SERVICE_NAME = 'DD_TRACE_PRESTO_SERVICE_NAME'
          ENV_PEER_SERVICE = 'DD_TRACE_PRESTO_PEER_SERVICE'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_PRESTO_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_PRESTO_ANALYTICS_SAMPLE_RATE'
          DEFAULT_PEER_SERVICE_NAME = 'presto'
          SPAN_QUERY = 'presto.query'
          SPAN_KILL = 'presto.kill_query'
          TAG_SCHEMA_NAME = 'presto.schema'
          TAG_CATALOG_NAME = 'presto.catalog'
          TAG_USER_NAME = 'presto.user'
          TAG_TIME_ZONE = 'presto.time_zone'
          TAG_LANGUAGE = 'presto.language'
          TAG_PROXY = 'presto.http_proxy'
          TAG_MODEL_VERSION = 'presto.model_version'
          TAG_QUERY_ID = 'presto.query.id'
          TAG_QUERY_ASYNC = 'presto.query.async'
          TAG_COMPONENT = 'presto'
          TAG_OPERATION_QUERY = 'query'
          TAG_OPERATION_KILL = 'kill'
          TAG_SYSTEM = 'presto'
          PEER_SERVICE_SOURCES = (Array[Ext::TAG_SCHEMA_NAME] +
                                            Contrib::Ext::DB::PEER_SERVICE_SOURCES).freeze
        end
      end
    end
  end
end
