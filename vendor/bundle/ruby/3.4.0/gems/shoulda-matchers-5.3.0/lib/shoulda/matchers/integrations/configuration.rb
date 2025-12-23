require 'set'

module Shoulda
  module Matchers
    module Integrations
      # @private
      class Configuration
        def self.apply(&block)
          new(&block).apply
        end

        attr_reader :test_frameworks

        def initialize(&block)
          @test_frameworks = Set.new
          @libraries = Set.new

          test_framework :missing_test_framework
          library :missing_library

          block.call(self)
        end

        def test_framework(name)
          clear_default_test_framework
          @test_frameworks << Integrations.find_test_framework!(name)
        end

        def library(name)
          @libraries << Integrations.find_library!(name)
        end

        def apply
          if no_test_frameworks_added? && no_libraries_added?
            raise ConfigurationError, <<EOT
shoulda-matchers is not configured correctly. You need to specify at least one
test framework and/or library. For example:

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
EOT
          end

          @test_frameworks.each do |test_framework|
            test_framework.include(Shoulda::Matchers::Independent)
            @libraries.each { |library| library.integrate_with(test_framework) }
          end

          self
        end

        private

        def clear_default_test_framework
          @test_frameworks.select!(&:present?)
        end

        def no_test_frameworks_added?
          @test_frameworks.empty? || @test_frameworks.none?(&:present?)
        end

        def no_libraries_added?
          @libraries.empty?
        end
      end
    end
  end
end
