# frozen_string_literal: true

require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module SuckerPunch
        # Description of SuckerPunch integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('2.0.0')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :sucker_punch, auto_patch: true

          def self.version
            Gem.loaded_specs['sucker_punch'] && Gem.loaded_specs['sucker_punch'].version
          end

          def self.loaded?
            !defined?(::SuckerPunch).nil?
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
