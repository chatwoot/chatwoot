# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Pg
        # pg integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_PG_ENABLED'
          ENV_SERVICE_NAME = 'DD_TRACE_PG_SERVICE_NAME'
          ENV_PEER_SERVICE = 'DD_TRACE_PG_PEER_SERVICE'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_PG_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_PG_ANALYTICS_SAMPLE_RATE'
          DEFAULT_PEER_SERVICE_NAME = 'pg'
          SPAN_EXEC = 'pg.exec'
          SPAN_EXEC_PARAMS = 'pg.exec.params'
          SPAN_EXEC_PREPARED = 'pg.exec.prepared'
          SPAN_ASYNC_EXEC = 'pg.async.exec'
          SPAN_ASYNC_EXEC_PARAMS = 'pg.async.exec.params'
          SPAN_ASYNC_EXEC_PREPARED = 'pg.async.exec.prepared'
          SPAN_SYNC_EXEC = 'pg.sync.exec'
          SPAN_SYNC_EXEC_PARAMS = 'pg.sync.exec.params'
          SPAN_SYNC_EXEC_PREPARED = 'pg.sync.exec.prepared'
          TAG_DB_NAME = 'pg.db.name'
          TAG_COMPONENT = 'pg'
          TAG_OPERATION_QUERY = 'query'
          TAG_SYSTEM = 'postgresql'
          PEER_SERVICE_SOURCES = Contrib::Ext::DB::PEER_SERVICE_SOURCES.freeze
        end
      end
    end
  end
end
