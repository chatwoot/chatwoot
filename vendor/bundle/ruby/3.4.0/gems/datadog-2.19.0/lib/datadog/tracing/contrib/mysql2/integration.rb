# frozen_string_literal: true

require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module Mysql2
        # Description of Mysql2 integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('0.3.21')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :mysql2

          def self.version
            Gem.loaded_specs['mysql2'] && Gem.loaded_specs['mysql2'].version
          end

          def self.loaded?
            !defined?(::Mysql2).nil?
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
