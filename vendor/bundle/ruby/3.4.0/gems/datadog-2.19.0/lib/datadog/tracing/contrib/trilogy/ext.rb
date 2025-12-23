# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Trilogy
        # Trilogy integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_TRILOGY_ENABLED'
          ENV_SERVICE_NAME = 'DD_TRACE_TRILOGY_SERVICE_NAME'
          ENV_PEER_SERVICE = 'DD_TRACE_TRILOGY_PEER_SERVICE'

          ENV_ANALYTICS_ENABLED = 'DD_TRACE_TRILOGY_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_TRILOGY_ANALYTICS_SAMPLE_RATE'
          DEFAULT_PEER_SERVICE_NAME = 'trilogy'
          SPAN_QUERY = 'trilogy.query'
          TAG_DB_NAME = 'trilogy.db.name'
          TAG_COMPONENT = 'trilogy'
          TAG_OPERATION_QUERY = 'query'
          TAG_SYSTEM = 'mysql'
          PEER_SERVICE_SOURCES = (Array[Ext::TAG_DB_NAME] + Contrib::Ext::DB::PEER_SERVICE_SOURCES).freeze
        end
      end
    end
  end
end
