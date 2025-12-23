# frozen_string_literal: true

# typed: false

require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module Roda
        # Description of Roda integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('2.0.0')
          MAXIMUM_VERSION = Gem::Version.new('4.0.0')

          register_as :roda

          def self.version
            Gem.loaded_specs['roda'] && Gem.loaded_specs['roda'].version
          end

          def self.loaded?
            !defined?(::Roda).nil?
          end

          def self.compatible?
            super && version >= MINIMUM_VERSION && version < MAXIMUM_VERSION
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
