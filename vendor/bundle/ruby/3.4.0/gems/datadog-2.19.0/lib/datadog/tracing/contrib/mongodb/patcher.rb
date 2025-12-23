# frozen_string_literal: true

require_relative '../patcher'
require_relative 'ext'
require_relative 'instrumentation'

module Datadog
  module Tracing
    module Contrib
      module MongoDB
        # Patcher enables patching of 'mongo' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            ::Mongo::Client.include(Instrumentation::Client)
            add_mongo_monitoring
          end

          def add_mongo_monitoring
            # Subscribe to all COMMAND queries with our subscriber class
            ::Mongo::Monitoring::Global.subscribe(::Mongo::Monitoring::COMMAND, MongoCommandSubscriber.new)
          end
        end
      end
    end
  end
end
