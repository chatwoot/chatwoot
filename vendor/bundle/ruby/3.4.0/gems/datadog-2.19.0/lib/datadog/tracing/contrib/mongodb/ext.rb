# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module MongoDB
        # MongoDB integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_MONGO_ENABLED'
          ENV_SERVICE_NAME = 'DD_TRACE_MONGO_SERVICE_NAME'
          ENV_PEER_SERVICE = 'DD_TRACE_MONGO_PEER_SERVICE'
          # @!visibility private
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_MONGO_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_MONGO_ANALYTICS_SAMPLE_RATE'
          ENV_JSON_COMMAND = 'DD_TRACE_MONGO_JSON_COMMAND'
          DEFAULT_PEER_SERVICE_NAME = 'mongodb'
          SPAN_COMMAND = 'mongo.cmd'
          SPAN_TYPE_COMMAND = 'mongodb'
          TAG_COLLECTION = 'mongodb.collection'
          TAG_DB = 'mongodb.db'
          TAG_OPERATION = 'mongodb.operation'
          TAG_QUERY = 'mongodb.query'
          TAG_ROWS = 'mongodb.rows'
          TAG_COMPONENT = 'mongodb'
          TAG_OPERATION_COMMAND = 'command'
          TAG_SYSTEM = 'mongodb'
          PEER_SERVICE_SOURCES = (Array[Ext::TAG_DB] + Contrib::Ext::DB::PEER_SERVICE_SOURCES).freeze

          # Temporary namespace to accommodate unified tags which has naming collision, before
          # making breaking changes
          module DB
            TAG_COLLECTION = 'db.mongodb.collection'
          end
        end
      end
    end
  end
end
