module Shoulda
  module Matchers
    module Integrations
      module TestFrameworks
        # @private
        class TestUnit
          Integrations.register_test_framework(self, :test_unit)

          def validate!
          end

          def include(*modules, **_options)
            test_case_class.class_eval do
              include(*modules)
              extend(*modules)
            end
          end

          def n_unit?
            true
          end

          def present?
            true
          end

          private

          def test_case_class
            ::Test::Unit::TestCase
          end
        end
      end
    end
  end
end
