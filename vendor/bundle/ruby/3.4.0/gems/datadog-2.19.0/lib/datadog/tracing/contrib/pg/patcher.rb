# frozen_string_literal: true

require_relative '../patcher'
require_relative 'instrumentation'

module Datadog
  module Tracing
    module Contrib
      module Pg
        # Patcher enables patching of 'pg' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            patch_pg_connection
          end

          def patch_pg_connection
            ::PG::Connection.include(Instrumentation)
          end
        end
      end
    end
  end
end
