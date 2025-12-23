# frozen_string_literal: true

require_relative '../patcher'
require_relative 'database'
require_relative 'dataset'

module Datadog
  module Tracing
    module Contrib
      module Sequel
        # Patcher enables patching of 'sequel' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            patch_sequel_database
            patch_sequel_dataset
          end

          def patch_sequel_database
            ::Sequel::Database.include(Database)
          end

          def patch_sequel_dataset
            ::Sequel::Dataset.include(Dataset)
          end
        end
      end
    end
  end
end
