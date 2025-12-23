# frozen_string_literal: true

require_relative '../integration'
require_relative 'ext'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module Sneakers
        # Description of Sneakers integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('2.12.0')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :sneakers, auto_patch: true

          def self.version
            Gem.loaded_specs['sneakers'] && Gem.loaded_specs['sneakers'].version
          end

          def self.loaded?
            !defined?(::Sneakers).nil?
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
