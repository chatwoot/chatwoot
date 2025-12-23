module Shoulda
  module Matchers
    module Integrations
      module Libraries
        # @private
        class Routing
          Integrations.register_library(self, :routing)

          include Integrations::Inclusion
          include Integrations::Rails

          def integrate_with(test_framework)
            test_framework.include(matchers_module, type: :routing)

            include_into(::ActionController::TestCase, matchers_module)
          end

          private

          def matchers_module
            Shoulda::Matchers::Routing
          end
        end
      end
    end
  end
end
