module Shoulda
  module Matchers
    module Integrations
      module TestFrameworks
        # @private
        class Rspec
          Integrations.register_test_framework(self, :rspec)

          def validate!
          end

          def include(*modules, **options)
            ::RSpec.configure do |config|
              config.include(*modules, **options)
            end
          end

          def n_unit?
            false
          end

          def present?
            true
          end
        end
      end
    end
  end
end
