# frozen_string_literal: true

require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module Sequel
        # Description of Sequel integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('3.41')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :sequel, auto_patch: false

          def self.version
            Gem.loaded_specs['sequel'] && Gem.loaded_specs['sequel'].version
          end

          def self.loaded?
            !defined?(::Sequel).nil?
          end

          def self.compatible?
            super && version >= MINIMUM_VERSION
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
