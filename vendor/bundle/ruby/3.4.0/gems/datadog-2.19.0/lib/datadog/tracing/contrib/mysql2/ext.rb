# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Mysql2
        # Mysql2 integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_MYSQL2_ENABLED'
          ENV_SERVICE_NAME = 'DD_TRACE_MYSQL2_SERVICE_NAME'
          ENV_PEER_SERVICE = 'DD_TRACE_MYSQL2_PEER_SERVICE'

          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_MYSQL2_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_MYSQL2_ANALYTICS_SAMPLE_RATE'
          DEFAULT_PEER_SERVICE_NAME = 'mysql2'
          SPAN_QUERY = 'mysql2.query'
          TAG_DB_NAME = 'mysql2.db.name'
          TAG_COMPONENT = 'mysql2'
          TAG_OPERATION_QUERY = 'query'
          TAG_SYSTEM = 'mysql'
          PEER_SERVICE_SOURCES = (Array[Ext::TAG_DB_NAME] + Contrib::Ext::DB::PEER_SERVICE_SOURCES).freeze
        end
      end
    end
  end
end
