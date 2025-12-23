module Shoulda
  module Matchers
    module Integrations
      module TestFrameworks
        # @private
        class MissingTestFramework
          Integrations.register_test_framework(self, :missing_test_framework)

          def validate!
            raise TestFrameworkNotConfigured, <<-EOT
You need to set a test framework. Please add the following to your
test helper:

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    # Choose one:
    with.test_framework :rspec
    with.test_framework :minitest    # or, :minitest_5
    with.test_framework :minitest_4
    with.test_framework :test_unit
  end
end
            EOT
          end

          def include(*modules, **options)
          end

          def n_unit?
            false
          end

          def present?
            false
          end
        end
      end
    end
  end
end
