module Shoulda
  module Matchers
    # @private
    module Integrations
      class << self
        def register_library(klass, name)
          library_registry.register(klass, name)
        end

        def find_library!(name)
          library_registry.find!(name)
        end

        def register_test_framework(klass, name)
          test_framework_registry.register(klass, name)
        end

        def find_test_framework!(name)
          test_framework_registry.find!(name)
        end

        private

        def library_registry
          @_library_registry ||= Registry.new
        end

        def test_framework_registry
          @_test_framework_registry ||= Registry.new
        end
      end
    end
  end
end

require 'shoulda/matchers/integrations/configuration'
require 'shoulda/matchers/integrations/configuration_error'
require 'shoulda/matchers/integrations/inclusion'
require 'shoulda/matchers/integrations/rails'
require 'shoulda/matchers/integrations/registry'

require 'shoulda/matchers/integrations/libraries'
require 'shoulda/matchers/integrations/test_frameworks'
