# frozen_string_literal: true

require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module Dalli
        # Description of Dalli integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('2.0.0')
          DALLI_PROTOCOL_BINARY_VERSION = Gem::Version.new('3.0.0')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :dalli, auto_patch: true

          def self.version
            Gem.loaded_specs['dalli'] && Gem.loaded_specs['dalli'].version
          end

          def self.loaded?
            !defined?(::Dalli).nil?
          end

          def self.compatible?
            super && version >= MINIMUM_VERSION
          end

          def self.dalli_class
            if version >= DALLI_PROTOCOL_BINARY_VERSION
              ::Dalli::Protocol::Binary
            else
              ::Dalli::Server
            end
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
