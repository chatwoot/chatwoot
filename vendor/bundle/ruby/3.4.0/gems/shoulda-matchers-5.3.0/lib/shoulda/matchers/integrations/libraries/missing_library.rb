module Shoulda
  module Matchers
    module Integrations
      module Libraries
        # @private
        class MissingLibrary
          Integrations.register_library(self, :missing_library)

          def integrate_with(test_framework)
          end

          def rails?
            false
          end
        end
      end
    end
  end
end
