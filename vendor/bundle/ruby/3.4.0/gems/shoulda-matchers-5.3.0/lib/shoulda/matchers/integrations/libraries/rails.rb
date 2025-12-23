module Shoulda
  module Matchers
    module Integrations
      module Libraries
        # @private
        class Rails
          Integrations.register_library(self, :rails)

          include Integrations::Rails

          SUB_LIBRARIES = [
            :active_model,
            :active_record,
            :action_controller,
            :routing,
          ].freeze

          def integrate_with(test_framework)
            Shoulda::Matchers.assertion_exception_class =
              ActiveSupport::TestCase::Assertion

            SUB_LIBRARIES.each do |name|
              library = Integrations.find_library!(name)
              library.integrate_with(test_framework)
            end
          end
        end
      end
    end
  end
end
