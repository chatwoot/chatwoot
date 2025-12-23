# frozen_string_literal: true

require_relative '../integration'

require_relative 'ext'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module Rails
        # Description of Rails integration
        class Integration
          include Contrib::Integration

          # The version of Rails lives in Ext because the `rails/patcher.rb` indirectly loads
          # all Rails components, and those components need the Rails version. Declaring the version
          # here would cause a circular dependency.
          MINIMUM_VERSION = Ext::MINIMUM_VERSION

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :rails, auto_patch: false

          def self.version
            Gem.loaded_specs['railties'] && Gem.loaded_specs['railties'].version
          end

          def self.loaded?
            !defined?(::Rails).nil?
          end

          def self.compatible?
            super && version >= MINIMUM_VERSION
          end

          def self.patchable?
            super && !ENV.key?(Ext::ENV_DISABLE)
          end

          def new_configuration
            Configuration::Settings.new
          end

          def patcher
            Patcher
          end
        end
      end
    end
  end
end
