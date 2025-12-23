module Shoulda
  module Matchers
    module Integrations
      module Libraries
        # @private
        class ActiveRecord
          Integrations.register_library(self, :active_record)

          include Integrations::Inclusion
          include Integrations::Rails

          def integrate_with(test_framework)
            test_framework.include(matchers_module, type: :model)
            include_into(ActiveSupport::TestCase, matchers_module)
          end

          private

          def matchers_module
            Shoulda::Matchers::ActiveRecord
          end
        end
      end
    end
  end
end
